import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

import 'dart:developer';
import 'camera_view.dart';
import 'painters/text_detector_painter.dart';

final openAI = ChatGPT.instance.builder("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", baseOption: HttpSetup(receiveTimeout: 6000));

class TextRecognizerView extends StatefulWidget {
  @override
  State<TextRecognizerView> createState() => _TextRecognizerViewState();
}

class _TextRecognizerViewState extends State<TextRecognizerView> {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.chinese);
  bool _canProcess = true;
  bool _isBusy = false;
  String? _text;

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: 'Text Detector',
      text: _text,
      onImage: (inputImage) {
        processImage(inputImage);
      },
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final recognizedText = await _textRecognizer.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
        final request = CompleteReq(
          prompt: '${recognizedText.text} Näytä lasku ja vastaus.',
          model: kTranslateModelV3,
          max_tokens: 20000,
        );

        openAI.onCompleteStream(request: request).first.then((response) { 
          print(recognizedText.text);
          var text = response?.choices.first.text;
          Navigator.push(context, MaterialPageRoute(builder: (ctx) => Container(color: Color(0xffffffff), child: Text(text!))));
        });

    } else {
        final request = CompleteReq(
          prompt: recognizedText.text,
          model: kTranslateModelV3,
          max_tokens: 20000,
        );

        openAI.onCompleteStream(request: request).first.then((response) { 
          print(recognizedText.text);
          var text = response?.choices.first.text;
          Navigator.push(context, MaterialPageRoute(builder: (ctx) => Container(color: Color(0xffffffff), child: Text(text!, style: TextStyle(fontSize: 12)))));
        });
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
