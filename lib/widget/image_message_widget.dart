import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:livehelp/model/message.dart';
import 'package:livehelp/utils/function_utils.dart';

class ImageMessageWidget extends StatefulWidget {
  const ImageMessageWidget({ super.key,required this.link, required Message message,});
  final String link;
  @override
  State<ImageMessageWidget> createState() => _MyImageMessageWidgetState();
}

class _MyImageMessageWidgetState extends State<ImageMessageWidget> {
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        FunctionUtils.showImageDialog(context, widget.link);
      },
      child: CachedNetworkImage(
        imageUrl:widget.link,
        progressIndicatorBuilder: (context, url, downloadProgress) =>
            CircularProgressIndicator(value: downloadProgress.progress),
        errorWidget: (context, url, error) => Icon(Icons.error),
      ),
    );
  }
}
