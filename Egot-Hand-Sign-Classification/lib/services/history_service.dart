import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_database/firebase_database.dart';

class ClassificationResult {
  final String label;
  final double confidence;
  final DateTime timestamp;
  final String? imagePath;
  final Map<String, double>? probabilities;

  ClassificationResult({
    required this.label,
    required this.confidence,
    required this.timestamp,
    this.imagePath,
    this.probabilities,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'confidence': confidence,
    'timestamp': timestamp.toIso8601String(),
    'imagePath': imagePath,
    'probabilities': probabilities,
  };

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      label: json['label'],
      confidence: json['confidence'],
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
      probabilities: json['probabilities'] != null
          ? Map<String, double>.from(json['probabilities'])
          : null,
    );
  }
}

class HistoryService {
  static const String _keyHistory = 'classification_history';
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'detections',
  );

  Future<void> saveResult({
    required String label,
    required double confidence,
    File? imageFile,
    Map<String, double>? probabilities,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    String? localImagePath;
    if (imageFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String targetPath = path.join(directory.path, fileName);
      final File savedImage = await imageFile.copy(targetPath);
      localImagePath = savedImage.path;
    }

    final newResult = ClassificationResult(
      label: label,
      confidence: confidence,
      timestamp: DateTime.now(),
      imagePath: localImagePath,
      probabilities: probabilities,
    );

    history.insert(0, newResult);

    // Limit history size to 50
    if (history.length > 50) {
      // Optionally delete old images here if needed
      history.removeRange(50, history.length);
    }

    final String encodedData = jsonEncode(
      history.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_keyHistory, encodedData);

    // Sync to Firebase
    try {
      await _dbRef.push().set({
        'label': label,
        'confidence': confidence,
        'timestamp': DateTime.now().toIso8601String(),
        'probabilities': probabilities,
        // Note: Image path is local, not uploading image to Storage yet
      });
    } catch (e) {
      // Fail silently for now or log
      print('Firebase Sync Error: $e');
    }
  }

  Future<List<ClassificationResult>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_keyHistory);
    if (data == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => ClassificationResult.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // In a real app, delete all linked images here
    await prefs.remove(_keyHistory);
  }

  Future<AnalyticsData> getAnalytics() async {
    final history = await getHistory();
    if (history.isEmpty) {
      return AnalyticsData(
        totalDetections: 0,
        averageConfidence: 0.0,
        topSign: 'None',
        topSignCount: 0,
        last7Days: List.filled(7, 0),
        last30Days: List.filled(30, 0),
        last12Months: List.filled(12, 0),
        classFrequency: {},
      );
    }

    // 1. Total and Average
    final total = history.length;
    final avgConf =
        history.fold(0.0, (sum, item) => sum + item.confidence) / total;

    // 2. Class Frequency
    final frequency = <String, int>{};
    for (var item in history) {
      frequency[item.label] = (frequency[item.label] ?? 0) + 1;
    }

    // 3. Top Sign
    var topSign = 'None';
    var topCount = 0;
    if (frequency.isNotEmpty) {
      final sortedEntries = frequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topSign = sortedEntries.first.key;
      topCount = sortedEntries.first.value;
    }

    // 4. Weekly Activity (Last 7 days) & Monthly (Last 30 days) & Yearly (Last 12 months)
    final last7Days = List.filled(7, 0);
    final last30Days = List.filled(30, 0);
    final last12Months = List.filled(12, 0);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var item in history) {
      final itemDate = DateTime(
        item.timestamp.year,
        item.timestamp.month,
        item.timestamp.day,
      );

      // Last 7 Days
      final diff7 = today.difference(itemDate).inDays;
      if (diff7 >= 0 && diff7 < 7) {
        last7Days[6 - diff7]++;
      }

      // Last 30 Days
      final diff30 = today.difference(itemDate).inDays;
      if (diff30 >= 0 && diff30 < 30) {
        last30Days[29 - diff30]++;
      }

      // Last 12 Months
      // Calculate month difference: (yearDiff * 12) + monthDiff
      final monthDiff =
          (today.year - itemDate.year) * 12 + (today.month - itemDate.month);
      if (monthDiff >= 0 && monthDiff < 12) {
        last12Months[11 - monthDiff]++;
      }
    }

    return AnalyticsData(
      totalDetections: total,
      averageConfidence: avgConf,
      topSign: topSign,
      topSignCount: topCount,
      last7Days: last7Days,
      last30Days: last30Days,
      last12Months: last12Months,
      classFrequency: frequency,
    );
  }
}

class AnalyticsData {
  final int totalDetections;
  final double averageConfidence;
  final String topSign;
  final int topSignCount;
  final List<int> last7Days;
  final List<int> last30Days;
  final List<int> last12Months;
  final Map<String, int> classFrequency;

  AnalyticsData({
    required this.totalDetections,
    required this.averageConfidence,
    required this.topSign,
    required this.topSignCount,
    required this.last7Days,
    required this.last30Days,
    required this.last12Months,
    required this.classFrequency,
  });
}
