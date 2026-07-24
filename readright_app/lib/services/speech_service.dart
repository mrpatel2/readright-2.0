/// lib/services/speech_service.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterTts _tts = FlutterTts();

  Future<bool> initialize() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;

    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.4);
    return true;
  }

  // ---------------------------------------------------------------------------
  // RECORD AUDIO → WAV
  // Azure requires:
  //  - PCM 16-bit
  //  - Mono
  //  - 16kHz sample rate
  //  - Proper RIFF WAV header
  // ---------------------------------------------------------------------------
  Future<String?> recordAudio({
    required String studentId,
    Duration duration = const Duration(seconds: 3),
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings/$studentId');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    final pcmPath =
        "${recordingsDir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.pcm";
    final wavPath = pcmPath.replaceAll('.pcm', '.wav');

    // Start raw PCM recording
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: pcmPath,
    );

    await Future.delayed(duration);
    final result = await _recorder.stop();

    if (result == null) {
      print('❌ Audio recording failed to stop properly.');
      return null;
    }

    final pcmFile = File(result);
    if (!await pcmFile.exists()) {
      print('❌ PCM file not found at path: $result');
      return null;
    }

    final pcmData = await pcmFile.readAsBytes();

    final wavData = _pcmToWav(
      pcmData,
      sampleRate: 16000,
      channels: 1,
      bitsPerSample: 16,
    );

    // Save the WAV file
    final wavFile = File(wavPath);
    await wavFile.writeAsBytes(wavData);
    print('✅ Audio saved to: $wavPath');

    // Delete the temporary PCM file
    await pcmFile.delete();

    return wavPath;
  }

  // ---------------------------------------------------------------------------
  // WAV ENCODER — Microsoft-correct format for Azure Speech REST API
  // ---------------------------------------------------------------------------
  Uint8List _pcmToWav(
    Uint8List pcm, {
    required int sampleRate,
    required int channels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);

    final header = BytesBuilder();

    header.add(ascii.encode("RIFF"));
    header.add(_i32(36 + pcm.length));
    header.add(ascii.encode("WAVE"));

    header.add(ascii.encode("fmt "));
    header.add(_i32(16)); // Subchunk1 size
    header.add(_i16(1)); // Audio format = PCM
    header.add(_i16(channels));
    header.add(_i32(sampleRate));
    header.add(_i32(byteRate));
    header.add(_i16(blockAlign));
    header.add(_i16(bitsPerSample));

    header.add(ascii.encode("data"));
    header.add(_i32(pcm.length));
    header.add(pcm);

    return header.toBytes();
  }

  Uint8List _i16(int v) {
    final b = Uint8List(2);
    b.buffer.asByteData().setInt16(0, v, Endian.little);
    return b;
  }

  Uint8List _i32(int v) {
    final b = Uint8List(4);
    b.buffer.asByteData().setInt32(0, v, Endian.little);
    return b;
  }

  // ---------------------------------------------------------------------------
  // TEXT-TO-SPEECH
  // ---------------------------------------------------------------------------
  Future<void> speak(List<String> lines) async {
    await _tts.stop();

    for (final line in lines) {
      final completer = Completer<void>();

      _tts.setCompletionHandler(() {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await _tts.speak(line);
      await completer.future;
      await Future.delayed(const Duration(milliseconds: 120));
    }
  }

  // ---------------------------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------------------------
  Future<void> dispose() async {
    await _tts.stop();
    await _recorder.dispose();
  }
}
