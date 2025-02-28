import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livehelp/model/message.dart';
import 'package:livehelp/utils/function_utils.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class FileMessageWidget extends StatefulWidget {
  const FileMessageWidget({required Key key, required this.message})
      : super(key: key);
  final Message message;

  @override
  State<FileMessageWidget> createState() => _FileMessageWidgetState();
}

class _FileMessageWidgetState extends State<FileMessageWidget> {
  String fileName = "fileName";
  String completePath = '';
  bool doesFileExists = false;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    fileName = FunctionUtils.extractFileName(widget.message.msg!) ?? fileName;
    _initFilePath();
    
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        _checkFileExists();
      },
    );
  }

  Future<void> _initFilePath() async {
    try {
      if (Platform.isIOS) {
        final directory = await getApplicationDocumentsDirectory();
        completePath = '${directory.path}/$fileName';
      } else {
        // Android path
        completePath = '/storage/emulated/0/Download/LiveHelperChat/$fileName';
      }
      log('File path set to: $completePath');
    } catch (e) {
      log('Error setting file path: $e');
    }
  }

  Future<void> _checkFileExists() async {
    try {
      bool exists = await File(completePath).exists();
      setState(() {
        doesFileExists = exists;
      });
      log("DoesFileExist $fileName: $exists at $completePath");
    } catch (e) {
      log('Error checking if file exists: $e');
    }
  }

  Future<void> _openFile() async {
    try {
      final result = await OpenFile.open(completePath);
      log('Open file result: ${result.message}');
      
      if (result.type != ResultType.done) {
        FunctionUtils.showErrorMessage(
          message: "Could not open file: ${result.message}"
        );
      }
    } catch (e) {
      log('Error opening file: $e');
      FunctionUtils.showErrorMessage(
        message: "Error opening file: $e"
      );
    }
  }

  Future<void> _downloadAndOpenFile() async {
    setState(() {
      isDownloading = true;
    });
    
    try {
      final result = await FunctionUtils.downloadFile(
        widget.message.msg!,
        onProgress: (fileName, progress) {
          log('Downloading $fileName: $progress%');
        },
        onComplete: (path) {
          log('Download completed: $path');
          setState(() {
            doesFileExists = true;
            isDownloading = false;
          });
          _openFile();
        },
        onDownloadError: (error) {
          log('Download error: $error');
          setState(() {
            isDownloading = false;
          });
          FunctionUtils.showErrorMessage(message: "Download error: $error");
        },
        isiOS: Platform.isIOS,
      );
      
      if (result == null) {
        setState(() {
          isDownloading = false;
        });
      }
    } catch (e) {
      setState(() {
        isDownloading = false;
      });
      log('Error in download and open: $e');
      FunctionUtils.showErrorMessage(message: "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (isDownloading) return;
        
        if (doesFileExists) {
          _openFile();
        } else {
          _downloadAndOpenFile();
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDownloading 
                ? Icons.downloading
                : doesFileExists 
                    ? Icons.file_present 
                    : Icons.file_download,
            color: Colors.black45,
            size: 30,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.black),
            ),
          ),
          if (isDownloading)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}