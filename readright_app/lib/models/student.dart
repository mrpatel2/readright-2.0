// lib/models/student.dart
//
// Represents a single student within a teacher's class.
// Used by StudentRepository, StudentSelectionScreen, and StudentSessionService.

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id; // Firestore document id or local id
  final String name;
  final String avatar; // e.g. "tiger", "fox", etc.
  final String pin; // optional numeric pin, stored as string ("" = no PIN)
  final bool isAudioRecordingEnabled;

  Student({
    required this.id,
    required this.name,
    required this.avatar,
    required this.pin,
    this.isAudioRecordingEnabled = false,
  });

  // ---------- Firestore helpers ----------

  static Student fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final rawPin = data['pin'];
    final safePin = rawPin == null ? '' : rawPin.toString();

    return Student(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      avatar: (data['avatar'] ?? 'tiger') as String,
      pin: safePin,
      isAudioRecordingEnabled:
          (data['isAudioRecordingEnabled'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'avatar': avatar,
    'pin': pin,
    'isAudioRecordingEnabled': isAudioRecordingEnabled,
  };

  // ---------- JSON (for local storage) ----------

  factory Student.fromJson(Map<String, dynamic> json) {
    final rawPin = json['pin'];
    final safePin = rawPin == null ? '' : rawPin.toString();

    return Student(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? 'tiger',
      pin: safePin,
      isAudioRecordingEnabled:
          json['isAudioRecordingEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'pin': pin,
    'isAudioRecordingEnabled': isAudioRecordingEnabled,
  };

  String toJsonString() => jsonEncode(toJson());

  static Student fromJsonString(String src) {
    return Student.fromJson(jsonDecode(src) as Map<String, dynamic>);
  }

  // ---------- copyWith (used by StudentRepository) ----------

  Student copyWith({
    String? id,
    String? name,
    String? avatar,
    String? pin,
    bool? isAudioRecordingEnabled,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      pin: pin ?? this.pin,
      isAudioRecordingEnabled:
          isAudioRecordingEnabled ?? this.isAudioRecordingEnabled,
    );
  }
}
