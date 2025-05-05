import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livehelp/model/model.dart';
import 'package:livehelp/pages/chat/audio_recorder_controller.dart';
import 'package:livehelp/pages/chat/text_wdiget_.dart';
import 'package:livehelp/services/server_repository.dart';
import 'package:livehelp/utils/function_utils.dart';
import 'package:rxdart/subjects.dart';

//a class which contains the text-box for message, attach file button, audio record and
//send message button
class SendMessageRowWidget extends StatefulWidget {
  const SendMessageRowWidget({
    required Key key,
    required this.chat,
    required this.server,
    required this.isOwnerOfChat,
    required this.submitMessage,
    this.cannedMsgs = const [],
  }) : super(key: key);
  final Chat? chat;
  final Server server;
  final bool isOwnerOfChat;
  final Function(String messaage,{String? sender,}) submitMessage;
  final List<dynamic> cannedMsgs;
  @override
  State<SendMessageRowWidget> createState() => _SendMessageRowWidgetState();
}

class _SendMessageRowWidgetState extends State<SendMessageRowWidget> {
  //Audio recorder controller
  late AudioRecorderController _audioConrtoller;
  String? recordedFilePath;
  bool isRecording = false;
  Timer? _timer;
  int dummyValue = 0;
  TextEditingController textController = TextEditingController();
  bool isDepartmentWhatsapp = true;
  ServerRepository? serverRepository;
  final _writingSubject = PublishSubject<String>();
  bool isUploading = false;
  bool isWhisperModeOn = false;
  @override
  void initState() {
    super.initState();
    _audioConrtoller = AudioRecorderController();
    serverRepository = RepositoryProvider.of<ServerRepository>(
        context); //subject.stream.debounce(new Duration(milliseconds: 300)).listen(_textChanged);
    // _writingSubject.stream.listen(_textChanged);
    // if (widget.chat?.department_name != null) {
    //   String depName = widget.chat!.department_name!.toLowerCase();
    //   if (depName.toLowerCase().startsWith('w')) {
    //     isDepartmentWhatsapp = true;
    //   }
    // }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioConrtoller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Visibility(visible: isUploading, child: UploadingWidget()),
        Container(  // Add this Container to wrap the Row
            color: Colors.white, // Set your desired background color here
            child: Row(
              children: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert),
                  onSelected: (String choice) {
                  if (choice == 'canned_messages') {
                    showModalBottomSheet<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: ListView.builder(
                        reverse: false,
                        padding: EdgeInsets.all(6.0),
                        itemCount: widget.cannedMsgs.length,
                        itemBuilder: (_, int index) {
                          Map canMsg = widget.cannedMsgs[index];
                          return Container(
                          child: ListTile(
                            title: Text(canMsg["title"]),
                            isThreeLine: true,
                            subtitle: Text(canMsg["msg"]),
                            onTap: () {
                            textController.text = canMsg["msg"];
                            Navigator.pop(context);
                            },
                          ),
                          );
                        },
                        ),
                      ),
                      );
                    },
                    );
                  } else if (choice == 'whisper_mode') {
                    setState(() {
                    isWhisperModeOn = !isWhisperModeOn;
                    });
                  } else if (choice == 'attach_file') {
                    _attachFile();
                  }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'canned_messages',
                    child: Row(
                    children: [
                      Icon(Icons.list, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Canned Messages'),
                    ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'whisper_mode',
                    child: Row(
                    children: [
                      Icon(
                      isWhisperModeOn ? Icons.hearing : Icons.hearing_disabled,
                      color: isWhisperModeOn ? Colors.blue : Colors.black54,
                      ),
                      SizedBox(width: 8),
                      Text(isWhisperModeOn ? 'Disable Whisper Mode' : 'Enable Whisper Mode'),
                    ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'attach_file',
                    child: Row(
                    children: [
                      Icon(Icons.attach_file, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('Attach File'),
                    ],
                    ),
                  ),
                  ],
                ),
                SizedBox(
                  width: 5,
                ),
                Flexible(
                  child: TextField(
                    controller: textController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    enableInteractiveSelection: true,
                    onChanged: (txt) => (_writingSubject.add(txt)),
                    onSubmitted: (value) {
                      widget.submitMessage(value,sender: isWhisperModeOn?"system":"operator");
                    },
                    decoration: widget.isOwnerOfChat
                        ? const InputDecoration(
                            hintText: "Enter a message to send",
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none)
                        : const InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            hintMaxLines: 1,
                            hintText: "You are not the owner of this chat",
                            hintStyle:
                            TextStyle(fontSize: 14)
                          ),
                  ),
                ),
                // Cancel recording button - only visible during recording
                Visibility(
                  visible: isRecording,
                  child: Container(
                    child: IconButton(
                      icon: Icon(
                        Icons.cancel,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        await cancelRecording();
                      },
                    ),
                  ),
                ),
                //Mic Functionality for sending voice messages
                Container(
                  child: IconButton(
                    icon: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      color: isRecording ? Colors.red : Colors.black,
                    ),
                    onPressed: () {
                      if (isRecording) {
                        stopRecording();
                      } else {
                        startRecording();
                      }
                    },
                  ),
                ),
                Container(
                  child: isRecording
                      ? Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: UpdatingTextWidget(),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            if (textController.text.isNotEmpty) {
                            widget.submitMessage(textController.text,sender: isWhisperModeOn?"system":"operator");
                              textController.clear();
                            }
                          }),
                ),
              ],
            ),
        )
      ],
    );
  }

  //start recording
  Future<void> startRecording() async {
    if (isRecording) {
      return;
    }
    if (await _audioConrtoller.hasPermission()) {
      // Start recording and handle the timer for the 30-second limit
      await _audioConrtoller.startRecording(
          fileName: 'testRecording$dummyValue',
          isDepartmentWhatsapp: isDepartmentWhatsapp);
      setState(() {
        isRecording = true;
      });
      // Automatically stop recording after 30 seconds
      _timer = Timer(Duration(seconds: 30), () {
        stopRecording();
      });
    } else {
      FunctionUtils.showErrorMessage(
          message: "Please grant mic permission front settings to continue");
    }
  }

  // This function will stop the recording process and send the audio message to user.....
  Future<void> stopRecording() async {
    try {
      if (isRecording) {
        // Stop the recording using the audio controller
        final path = await _audioConrtoller.stopRecording();
        dummyValue++;

        // Check if the recorded file exists before proceeding
        if (path != null) {
          final recordedFile = File(path);
          if (await recordedFile.exists()) {
            log('Recorded file saved at: ${recordedFile.path}');
            setState(() {
              recordedFilePath = recordedFile.path;
              isRecording = false;
              isUploading = true;
            });

            // Check file size before uploading
            int fileSize = await recordedFile.length();
            if (fileSize == 0) {
              setState(() {
                isUploading = false;
              });
              FunctionUtils.showErrorMessage(message: "Recording failed: empty file created");
              return;
            }

            try {
              var uploadedFile = await serverRepository!.uploadFile(
                widget.server,
                recordedFile,
                chatId: widget.chat?.id,
              );

              if (uploadedFile != null) {
                log(uploadedFile.toString());
                String fileMessage = FunctionUtils.buildFileMessage(
                  updateFileResponse: uploadedFile
                );
                widget.submitMessage(fileMessage);
              } else {
                FunctionUtils.showErrorMessage(message: "Failed to upload audio file");
              }
            } catch (e) {
              log("Upload error: ${e.toString()}");
              FunctionUtils.showErrorMessage(message: "Error uploading audio: ${e.toString()}");
            } finally {
              setState(() {
                isUploading = false;
              });
              // Try to delete the temporary file regardless of success
              try {
                await recordedFile.delete();
              } catch (e) {
                log("Error deleting temporary file: ${e.toString()}");
              }
            }
          } else {
            log('Recorded file does not exist: $path');
            setState(() {
              isUploading = false;
            });
            FunctionUtils.showErrorMessage(message: "Recorded file not saved! Try again");
          }
        } else {
          setState(() {
            isUploading = false;
            isRecording = false;
          });
          log('No path returned from recording');
          FunctionUtils.showErrorMessage(message: "Recording failed! No path returned");
        }
      }

      _timer?.cancel(); // Cancel the timer if recording is manually stopped
    } catch (e) {
      setState(() {
        isUploading = false;
        isRecording = false;
      });
      log("Error stopping recording: ${e.toString()}");
      FunctionUtils.showErrorMessage(message: "Error: ${e.toString()}");
    }
  }

  Future<void> cancelRecording() async {
    _timer?.cancel(); // Cancel the timer
    await _audioConrtoller.cancelRecording();
    setState(() {
      isRecording = false;
    });
  }

  Future<void> _attachFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        File file = File(result.files.single.path!);
        log(file.path);
        setState(() {
          isUploading = true;
        });
        final uploadedFileResult = await serverRepository!.uploadFile(widget.server, file);

        if (uploadedFileResult != null) {
          log(uploadedFileResult.toString());
          //send file to user
          widget.submitMessage(FunctionUtils.buildFileMessage(
              updateFileResponse: uploadedFileResult));
        }
        setState(() {
          isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      FunctionUtils.showErrorMessage(
          message: "Error:${e.toString()}");
    }
  }
}

// a widget which will be shown when an audio/image or file is being uploaded in chat
class UploadingWidget extends StatelessWidget {
  const UploadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        "Uploading ......",
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
