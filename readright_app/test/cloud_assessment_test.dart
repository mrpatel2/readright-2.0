import 'package:flutter_test/flutter_test.dart';
import 'package:readright_app/services/cloud_assessment_service.dart';
import 'package:readright_app/models/assessment_result.dart';
import 'test_config.dart';

void main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // LOAD FAKE DOTENV
  setUpAll(() async {
    await setupTestEnv(); // <- loads fake env before any tests run
  });

  test("CloudAssessmentService stores last result & word", () async {
    final cloud = CloudAssessmentService.instance;

    final fake = AssessmentResult(
      accuracy: 80,
      fluency: 70,
      completeness: 60,
      perWordAccuracy: {},
      provider: "test",
      recognizedText: "motor",
    );

    cloud.lastResult = fake;
    cloud.lastWord = "motor";

    expect(cloud.lastResult!.accuracy, 80);
    expect(cloud.lastWord, "motor");
  });
}
