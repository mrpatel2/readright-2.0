import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readright_app/services/cloud_fallback_assessor.dart';

void main() {
  test('fallback assessor never silently reports a graded zero score', () async {
    final assessor = CloudFallbackAssessor();

    final result = await assessor.assess(
      referenceText: 'cat',
      audioBytes: Uint8List.fromList(List.filled(4000, 1)),
    );

    // A false zero (graded: true, accuracy: 0) reads identically to a real
    // mispronunciation to the rest of the app. The fallback must mark the
    // attempt ungraded so callers offer a retry instead of a failure.
    expect(result.graded, isFalse);
    expect(result.provider, 'fallback');
  });
}
