import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassificationService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isBusy = false;

  bool get isBusy => _isBusy;

  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/tflite/model_unquant.tflite',
      );
      _labels = await _loadLabels('assets/tflite/labels.txt');
      debugPrint('Interpreter loaded successfully');
    } catch (e) {
      debugPrint('Failed to load interpreter: $e');
    }
  }

  Future<List<String>> _loadLabels(String path) async {
    final fileData = await rootBundle.loadString(path);
    return fileData.split('\n').where((s) => s.isNotEmpty).toList();
  }

  Future<Map<String, dynamic>?> classifyImage(File imageFile) async {
    if (_interpreter == null || _isBusy) return null;
    _isBusy = true;

    try {
      var image = img.decodeImage(imageFile.readAsBytesSync());
      if (image == null) return null;

      // Resize image to model input size (usually 224x224 for standard models, checking labels or generic)
      // Assuming 224x224 for Teachable Machine standard models
      var inputImage = img.copyResize(image, width: 224, height: 224);

      var input = _imageToByteListFloat32(inputImage, 224, 127.5, 127.5);
      var output = List.filled(
        1 * _labels.length,
        0.0,
      ).reshape([1, _labels.length]);

      _interpreter!.run(input, output);

      _isBusy = false;
      return _processOutput(output[0]);
    } catch (e) {
      debugPrint('Error classifying image: $e');
      _isBusy = false;
      return null;
    }
  }

  Uint8List _imageToByteListFloat32(
    img.Image image,
    int inputSize,
    double mean,
    double std,
  ) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Map<String, dynamic> _processOutput(List<dynamic> output) {
    var maxScore = -double.infinity;
    var maxIndex = -1;
    Map<String, double> probabilities = {};

    for (var i = 0; i < output.length; i++) {
      // Build probability map
      if (i < _labels.length) {
        String label = _labels[i].replaceFirst(RegExp(r'^\d+\s'), '');
        probabilities[label] = output[i];
      }

      if (output[i] > maxScore) {
        maxScore = output[i];
        maxIndex = i;
      }
    }

    if (maxIndex != -1 && maxIndex < _labels.length) {
      // Remove the index prefix usually found in TM labels (e.g. "0 Letter A")
      var label = _labels[maxIndex];
      // Regex to remove leading numbers if present
      label = label.replaceFirst(RegExp(r'^\d+\s'), '');

      return {
        'label': label,
        'confidence': maxScore,
        'probabilities': probabilities,
      };
    }

    return {
      'label': 'Unknown',
      'confidence': 0.0,
      'probabilities': probabilities,
    };
  }

  void close() {
    _interpreter?.close();
  }
}
