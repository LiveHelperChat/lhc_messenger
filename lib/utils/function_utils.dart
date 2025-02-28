import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http_parser/http_parser.dart';
import 'package:livehelp/model/file_upload_response.dart';
import 'package:mime/mime.dart';
import 'package:toastification/toastification.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FunctionUtils {
  static void showSuccessMessage(
      {required String message, int durationToShow = 5}) {
    toastification.show(
      title: Text("$message"),
      autoCloseDuration: Duration(seconds: durationToShow),
      type: ToastificationType.success,
    );
  }

  static void showErrorMessage(
      {required String message, int durationToShow = 5}) {
    toastification.show(
      title: Text("$message"),
      autoCloseDuration: Duration(seconds: durationToShow),
      type: ToastificationType.error,
    );
  }

  static String? extractFileName(String message) {
    // Find the starting position of "Download file - "
    int startIndex = message.indexOf('Download file - ');

    if (startIndex != -1) {
      // Move the start index to the beginning of the file name
      startIndex += 'Download file - '.length;

      // Find the position of the file type indicator (i.e., '[')
      int endIndex = message.indexOf(' [', startIndex);

      if (endIndex != -1) {
        // Extract and return the file name
        return message.substring(startIndex, endIndex);
      }
    }

    // Return empty string if not found
    return null;
  }

  static void showGeneralDialog(
      BuildContext context, Widget contentWidget, List<Widget> actionButtons) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero, // To avoid default padding in dialog

          content: contentWidget,
          actions: actionButtons,
        );
      },
    );
  }

  static void showImageDialog(BuildContext context, String link) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero, // To avoid default padding in dialog

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedNetworkImage(
                imageUrl: link,
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    CircularProgressIndicator(value: downloadProgress.progress),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // TextButton(
                  //   onPressed: () {
                  //     downloadImage(link); // Invoke the download method
                  //     Navigator.of(context)
                  //         .pop(); // Close the dialog after download
                  //   },
                  //   child: Text("Download"),
                  // ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pop(); // Close the dialog without action
                    },
                    child: Text("Cancel"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String buildFileMessage(
      {required FileUploadResponse updateFileResponse}) {
    return "[file=${updateFileResponse.id}_${updateFileResponse.securityHash}]";
  }

// Function to get the MediaType based on file URL
  static MediaType? getMediaType(String fileUrl) {
    log("Received file URL in getMediaType: $fileUrl");

    // Get the MIME type based on the file URL
    final mimeType = lookupMimeType(fileUrl);
    log("MIME type found: $mimeType");

    if (mimeType != null) {
      // Split the MIME type into main type and subtype
      final mainType = mimeType.split('/')[0];
      var subType = mimeType.split('/')[1];
      if (subType == "x-wav") {
        subType = "wav";
      }
      // Log the main type and subtype
      log("Main type: $mainType");
      log("Sub type: $subType");

      // Return media type based on the main type
      switch (mainType) {
        case 'image':
          log("Identified as an image type.");
          return MediaType('image', '$subType');
        case 'audio':
          log("Identified as an audio type.");
          return MediaType('audio', '$subType');
        case 'video': // Added case for video
          log("Identified as a video type.");
          return MediaType('video', '$subType');
        case 'application':
          if (subType == 'pdf') {
            log("Identified as PDF");
            return MediaType('file', 'pdf');
          }else{
             return MediaType('file', '');
          }
          
        default:
          log("Unsupported MIME type: $mimeType, returning null.");
          return null; // Return null for unsupported types
      }
    } else {
      log("MIME type is null for the provided URL.");
    }

    return null; // Return null if no valid MIME type is found
  }

  //Function which will return the type of message from received message object
  static MessageMediaType determineMessageMediaType(String? msg) {
   
    // Check for null or empty message
    if (msg == null || msg.isEmpty) {
       log("msg:${msg.toString()}");
      return MessageMediaType.Unknown;
    }

    // Check if it's a text message (plain text without HTML)
    final textPattern = RegExp(r'^[a-zA-Z0-9\s.,!?]+$');
    if (textPattern.hasMatch(msg)) {
      return MessageMediaType.Text;
    }

    // Check if it's an audio message (search for <audio> tag or specific href)
    if (msg.contains('<audio') || msg.contains('audio-download')||msg.contains('audio')) {
      return MessageMediaType.Audio;
    }

    // Check if it's an image message (search for <img> tag)
    if (msg.contains('<img')) {
      log("Image:$msg");
      return MessageMediaType.Image;
    }

    // Check if it's a file message (search for <a> with file download link)
    if (msg.contains('<a') && msg.contains('Download file')) {
        log("File:$msg");
      return MessageMediaType.File;
    }

    // Check if it's a video message (expand if future video types are added)
    if (msg.contains('<video')) {
      return MessageMediaType.Video;
    }
    // If no match, return Unknown
    return MessageMediaType.Unknown;
  }

//Function to extract media link from message if it is of any type like audio/image/file/
  static String? extractMediaLinkOrText(String msg) {
    // Determine the media type of the message
    MessageMediaType mediaType = determineMessageMediaType(msg);

    // Extract link or return the original message based on the media type
    switch (mediaType) {
      case MessageMediaType.Text:
        return msg; // Return the message itself for text messages
      case MessageMediaType.Image:
        return extractMediaLink(msg);
      case MessageMediaType.Audio:
        return extractMediaLink(msg);
      case MessageMediaType.Video:
        return extractMediaLink(msg);
      case MessageMediaType.File:
        return extractMediaLink(
            msg); // Files usually have anchor tags with href
      case MessageMediaType.Unknown:
      default:
        return null; // Return null for unknown message types
    }
  }

//Function to check if file user want to download already exist or not
  static Future<bool> doesFileExist(String fileName) async {
    // Define the download path
    String downloadPath =
        '/storage/emulated/0/Download/LiveHelperChat/$fileName'; // Update for your environment

    // Check if the file already exists
    final file = File(downloadPath);
    return await file.exists();
  }

//function to extract link from messages
  static String? extractMediaLink(String? msg) {
    if (msg == null) {
      return null;
    }
    // Regular expression to match 'href' or 'src' attributes for media links
    final urlPattern = RegExp(r'(href|src)="([^"]+)"');
    final match = urlPattern.firstMatch(msg);

    if (match != null) {
      return match
          .group(2); // Return the URL found in the 'href' or 'src' attribute
    }

    return null; // Return null if no URL is found
  }

  static Future<File?> downloadFile(
    String msgContent, {
    void onProgress(
      String? fileName,
      double progress,
    )?,
    void onComplete(String filePath)?,
    void onDownloadError(String error)?,
    bool isiOS = false,
  }) async {
    try {
      String downloadLink = extractMediaLink(msgContent)!;
      String fileName = extractFileName(msgContent)!;
      log("Downloading file: $fileName from $downloadLink");

      if (isiOS) {
        // For iOS, download file directly using http
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);

        // Create http client for file download
        final httpClient = http.Client();
        final request = http.Request('GET', Uri.parse(downloadLink));
        final response = await httpClient.send(request);

        final contentLength = response.contentLength ?? 0;
        int receivedBytes = 0;

        final sink = file.openWrite();

        await response.stream.listen(
          (List<int> chunk) {
            receivedBytes += chunk.length;
            sink.add(chunk);

            if (contentLength > 0 && onProgress != null) {
              final progress = receivedBytes / contentLength;
              onProgress(fileName, progress);
            }
          },
          onDone: () async {
            await sink.flush();
            await sink.close();
            httpClient.close();

            if (onComplete != null) {
              onComplete(filePath);
            }
          },
          onError: (error) {
            sink.close();
            httpClient.close();
            if (onDownloadError != null) {
              onDownloadError(error.toString());
            }
          },
          cancelOnError: true,
        );

        return file;
      } else {
        // Use flutter_file_downloader for Android
        return await FileDownloader.downloadFile(
          url: downloadLink,
          name: fileName,
          subPath: "LiveHelperChat/",
          onProgress: (fileName, progress) {
            if (onProgress != null) {
              onProgress(fileName, progress);
            }
          },
          onDownloadCompleted: (String path) {
            log('FILE DOWNLOADED TO PATH: $path');
            if (onComplete != null) {
              onComplete(path);
            }
          },
          onDownloadError: (String error) {
            if (onDownloadError != null) {
              onDownloadError(error);
            }
          }
        );
      }
    } catch (e) {
      log("Error downloading file: $e");
      showErrorMessage(message: e.toString());
      if (onDownloadError != null) {
        onDownloadError(e.toString());
      }
      return null;
    }
  }

//Function to append /fbmessenger/index at end of given url
 static String modifyUrl(String url) {
  // Remove trailing slashes from the URL to standardize it
  url = url.replaceAll(RegExp(r'/+$'), '');

  if (url.contains('/site_admin')) {
    // If the URL already contains /site_admin, append /fbmessenger/index
    return '$url/fbmessenger/index';
  } else {
    // If the URL does not contain /site_admin, append /site_admin/fbmessenger/index
    return '$url/site_admin/fbmessenger/index';
  }
}
}

enum MessageMediaType { Text, Image, Audio, Video, File, Unknown }
