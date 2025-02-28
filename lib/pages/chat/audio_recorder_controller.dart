import 'package:livehelp/utils/function_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'dart:developer';

class AudioRecorderController {
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Check if permissions are granted for recording
  Future<bool> hasPermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      log("Error checking permission: ${e.toString()}");
      return false;
    }
  }

  // Check if Opus encoding is supported
  Future<bool> _isOpusSupported() async {
    try {
      final isSupported = await _audioRecorder.isEncoderSupported(AudioEncoder.opus);
      return isSupported;
    } catch (e) {
      log("Error requesting permission: ${e.toString()}");
      // If checking support throws an error, assume it's not supported
      return false;
    }
  }

  // Get temporary file path for the recording
  Future<String> _getTempFilePath(String fileName) async {
    String fileExtension = Platform.isIOS ? ".m4a" : ".ogg";
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName$fileExtension';
  }

  // Start recording using a file path
  Future<void> startRecording({
    required String fileName,
    bool isDepartmentWhatsapp = false
  }) async {
    try {
      // Request permission if not already granted
      if (!await hasPermission()) {
        bool permissionGranted = await _requestPermission();
        if (!permissionGranted) {
          throw Exception("Microphone permission denied");
        }
      }

      // Use platform-specific encoders that are better supported
      AudioEncoder encoder;
      int numChannels;

      if (Platform.isIOS) {
        // AAC is better supported on iOS
        encoder = AudioEncoder.aacLc;
        numChannels = 1;
      } else {
        encoder = isDepartmentWhatsapp &&  await _isOpusSupported() ? AudioEncoder.opus : AudioEncoder.wav;
        numChannels = isDepartmentWhatsapp ? 1 : 2;
      }

      RecordConfig recordConfig = RecordConfig(
        encoder: encoder,
        numChannels: numChannels,
        bitRate: 128000, // Set a reasonable bitrate
        sampleRate: 44100, // Standard sample rate
      );

      final path = await _getTempFilePath(fileName);
      log("Recording to path: $path");

      // Make sure recording is stopped before starting a new one
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      await _audioRecorder.start(recordConfig, path: path);
      log("Recording started");
    } catch (e) {
      log("Error starting recording: ${e.toString()}");
      FunctionUtils.showErrorMessage(message: "Error starting recording: ${e.toString()}");
      rethrow;
    }
  }

  // Additional method to request permission explicitly
  Future<bool> _requestPermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      log("Error requesting permission: ${e.toString()}");
      return false;
    }
  }

  // Stop recording and return the file path of the saved recording
  Future<String?> stopRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        final path = await _audioRecorder.stop();
        log("Recording stopped, saved to: $path");
        return path;
      } else {
        log("No active recording to stop");
        return null;
      }
    } catch (e) {
      log("Error stopping recording: ${e.toString()}");
      FunctionUtils.showErrorMessage(message: "Error stopping recording: ${e.toString()}");
      return null;
    }
  }

  // Cancel recording without saving the file
  Future<void> cancelRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
        log("Recording cancelled");
      }
    } catch (e) {
      log("Error cancelling recording: ${e.toString()}");
    }
  }

  // Dispose method to clean up resources if necessary
  void dispose() {
    try {
      _audioRecorder.dispose();
    } catch (e) {
      log("Error disposing recorder: ${e.toString()}");
    }
  }
}