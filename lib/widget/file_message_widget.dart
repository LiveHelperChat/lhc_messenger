// ignore_for_file: must_be_immutable

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:livehelp/model/message.dart';
import 'package:livehelp/utils/function_utils.dart';
import 'package:open_file/open_file.dart';

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
  @override
  void initState() {
    super.initState();
    fileName = FunctionUtils.extractFileName(widget.message.msg!) ?? fileName;
    completePath = '/storage/emulated/0/Download/LiveHelperChat/$fileName';
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        FunctionUtils.doesFileExist(fileName).then(
          (value) {
            setState(() {
              doesFileExists = value;
              log("DoesFileExist $fileName:$value $doesFileExists");
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (doesFileExists) {
          OpenFile.open(completePath);
        }
        bool fileExists = await FunctionUtils.doesFileExist(fileName);
        if (fileExists) {
          try {
            setState(() {
              doesFileExists = fileExists;
            });
            OpenFile.open(completePath);
          } catch (e) {
            FunctionUtils.showErrorMessage(message: e.toString());
          }
        } else {
          final result = await FunctionUtils.downloadFile(widget.message.msg!,
              onProgress: onDownloadProgress);
          if (result != null) {
            try {
              OpenFile.open(completePath);
              setState(() {
                doesFileExists = true;
              });
            } catch (e) {
              FunctionUtils.showErrorMessage(message: e.toString());
            }
          }
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            doesFileExists ? Icons.file_present : Icons.file_download,
            color: Colors.black45,
            size: 30,
          ),
          Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.black),
          )
        ],
      ),
    );
  }

//function which will be giving file info and download progress
  void onDownloadProgress(fileName, progress) {}
}
