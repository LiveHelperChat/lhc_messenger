import 'package:livehelp/utils/function_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderController {
  final AudioRecorder _audioRecorder =
      AudioRecorder(); // Correct instance of Record class

  // Check if permissions are granted for recording
  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  // Get temporary file path for the recording
  Future<String> _getTempFilePath(String fileName,
     ) async {
    String fileExtention = ".ogg" ;
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName$fileExtention'; // Define file name and extension (WAV format)
  }

  // Start recording using a  file path
  Future<void> startRecording(
      {required String fileName, bool isDepartmentWhatsapp = false}) async {
    try {
      RecordConfig recordConfig = RecordConfig(
        encoder: isDepartmentWhatsapp ? AudioEncoder.opus : AudioEncoder.wav,
        numChannels: isDepartmentWhatsapp ? 1 : 2,
      );
      final path = await _getTempFilePath(fileName,
        );
      await _audioRecorder.start(recordConfig, path: path);
    } catch (e) {
      FunctionUtils.showErrorMessage(message: "Error:${e.toString()}");
    }
  }

  // Stop recording and return the file path of the saved recording
  Future<String?> stopRecording() async {
    return await _audioRecorder
        .stop(); // Stops recording and returns the file path
  }

  // Cancel recording without saving the file
  Future<void> cancelRecording() async {
    await _audioRecorder.stop(); // Stops the recording without saving
  }

  // Dispose method to clean up resources if necessary
  void dispose() {
    _audioRecorder.dispose();
  }
}
