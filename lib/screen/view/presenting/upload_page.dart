import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:marinode/screen/provider/upload_provider.dart';
import 'package:marinode/screen/utilities/color.dart';
import 'package:marinode/screen/utilities/string.dart';
import 'package:marinode/screen/utilities/text_style.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class UploadPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UploadProvider(FlutterLocalNotificationsPlugin()),
      child: Scaffold(
        backgroundColor: Appcolors.bgColor,
        appBar: AppBar(
          title: Center(
            child: Text(
              title,
              style: AppTextStyle.boldText(size: 26, color: Appcolors.white),
            ),
          ),
          backgroundColor: Appcolors.blue.withOpacity(.85),
        ),
        body: Consumer<UploadProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
//
//initial show upload button, after selection of file button disapper and show file name, the after complete the upload the button appear again and also disply a upload other file text
//
                  if (provider.uploadProgress == 1)
                    Text(
                      textAlign: TextAlign.center,
                      another,
                      style: AppTextStyle.regularText(
                        size: 16,
                        color: Appcolors.black,
                      ).copyWith(fontStyle: FontStyle.italic),
                    ),
                  if (provider.selectedFile == null ||
                      provider.uploadProgress >= 1.0)
                    _buttons(context, provider),
                  if (provider.selectedFile != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      textAlign: TextAlign.center,
                      "File: ${provider.selectedFile!.uri.pathSegments.last}",
                      style: AppTextStyle.semiboldText(
                        size: 20,
                        color: Appcolors.purple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (provider.uploadService
                        .isVideo(provider.selectedFile!.path)) ...[
                      _thumbnailAndVideoSection(provider),
                      const SizedBox(height: 8),
                      _buttons(context, provider, isPlayButton: true),
                    ],
                    const SizedBox(height: 20),
//
// below portion will disply while uploding the video
//
                    if (provider.uploadProgress != 1)
                      LinearProgressIndicator(
                        value: provider.uploadProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blueAccent,
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (provider.uploadProgress != 1)
                      Text(
                        textAlign: TextAlign.center,
                        "Uploading: ${(provider.uploadProgress * 100).toStringAsFixed(0)}%",
                        style: AppTextStyle.regularText(
                          size: 20,
                          color: Appcolors.black,
                        ),
                      ),
//
//this will disply after successfully upload the video
//
                    if (provider.uploadProgress == 1)
                      Text(
                        textAlign: TextAlign.center,
                        uploaded,
                        style: AppTextStyle.regularText(
                          size: 16,
                          color: Appcolors.black,
                        ).copyWith(fontStyle: FontStyle.italic),
                      ),

//
//check internet connectivity and then disply the below UI if there  is no internext
//
                    if (!provider.isConnected) ...[
                      Center(
                        child: Text(
                          'Internet Issue',
                          style: AppTextStyle.regularText(
                            size: 12,
                            color: Appcolors.red,
                            fontstyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => provider.checkConnectivity(),
                        child: Center(
                          child: Text(
                            "Retry",
                            style: AppTextStyle.regularText(
                                size: 18,
                                color: Appcolors.blue,
                                fontstyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buttons(context, UploadProvider provider,
      {bool isPlayButton = false}) {
    return GestureDetector(
      onTap: isPlayButton
          ? provider.toggleVideoPlayback
          : () async {
              await provider.checkConnectivity();
              if (provider.isNetworkAvailable) {
                provider.pickFile(context);
              }
            },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 150),
        height: 40,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          color: Appcolors.blue,
        ),
        child: isPlayButton
            ? Icon(
                provider.videoController?.value.isPlaying == true
                    ? Icons.pause
                    : Icons.play_arrow,
                size: 24,
                color: Appcolors.white,
              )
            : Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Text(
                      textAlign: TextAlign.center,
                      addfile,
                      style: AppTextStyle.mediumText(
                        size: 18,
                        color: Appcolors.white,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _thumbnailAndVideoSection(UploadProvider provider) {
    return SizedBox(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: provider.videoController!.value.aspectRatio,
          child: VideoPlayer(provider.videoController!),
        ),
      ),
    );
  }
}
