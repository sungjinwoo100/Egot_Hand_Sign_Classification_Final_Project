import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'library_page.dart';
import 'settings_page.dart';
import 'services/classification_service.dart';
import 'services/history_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ClassificationService _classificationService = ClassificationService();
  final HistoryService _historyService = HistoryService();
  final ImagePicker _picker = ImagePicker();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  File? _selectedImage;
  bool _isLiveCameraMode = true;
  String _detectedLabel = 'Waiting...';
  double _confidence = 0.0;
  bool _isProcessingLive = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _classificationService.initialize();
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {});

      if (_isLiveCameraMode) {
        _startAutoCapture();
      }
    }
  }

  void _startAutoCapture() {
    _stopAutoCapture();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isLiveCameraMode && _isCameraInitialized()) {
        _captureAndClassify();
      }
    });
  }

  void _stopAutoCapture() {
    _timer?.cancel();
    _timer = null;
  }

  bool _isCameraInitialized() {
    return _cameraController != null && _cameraController!.value.isInitialized;
  }

  // Alternative: Take picture for live classification to reuse the File-based service
  Future<void> _captureAndClassify({bool isManualCapture = false}) async {
    if (!_isCameraInitialized()) {
      return;
    }
    if (_isProcessingLive) return;

    _isProcessingLive = true;
    try {
      final XFile file = await _cameraController!.takePicture();
      final File imageFile = File(file.path);
      final result = await _classificationService.classifyImage(imageFile);

      if (mounted) {
        setState(() {
          if (isManualCapture) {
            _selectedImage = imageFile;
            _isLiveCameraMode = false;
            // Stop auto capture if we are switching to manual result view
            _stopAutoCapture();
          }
          if (result != null) {
            _detectedLabel = result['label'];
            _confidence = result['confidence'];

            if (isManualCapture) {
              _historyService.saveResult(
                label: _detectedLabel,
                confidence: _confidence,
                imageFile: imageFile,
                probabilities: result.containsKey('probabilities')
                    ? result['probabilities']
                    : null,
              );
            }
          }
        });
      }

      // Clean up the temporary file only if it's NOT a manual capture
      if (!isManualCapture) {
        try {
          await imageFile.delete();
        } catch (e) {
          debugPrint('Error deleting temp file: $e');
        }
      }
    } catch (e) {
      debugPrint('Error capturing/classifying: $e');
    } finally {
      _isProcessingLive = false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    _stopAutoCapture(); // Stop live capture when picking image
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _isLiveCameraMode = false;
        });

        final result = await _classificationService.classifyImage(
          _selectedImage!,
        );
        if (mounted && result != null) {
          setState(() {
            _detectedLabel = result['label'];
            _confidence = result['confidence'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  void dispose() {
    _stopAutoCapture();
    _cameraController?.dispose();
    _classificationService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1612), // Deep dark green/black
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hand Sign',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Title Section
              Text(
                'Detect Hand Sign',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select an input method to classify gestures.',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 24),

              // Input Methods
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLiveCameraMode = true;
                          _selectedImage = null;
                        });
                        _initializeCamera();
                        _startAutoCapture();
                      },
                      child: _buildInputCard(
                        title: 'Live Camera',
                        subtitle: 'REAL-TIME',
                        icon: Icons.videocam,
                        isSelected: _isLiveCameraMode,
                        isCamera: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: _buildInputCard(
                        title: 'Upload Photo',
                        subtitle: 'GALLERY',
                        icon: Icons.image,
                        isSelected: !_isLiveCameraMode,
                        isCamera: false,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Detection Result Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detection Result',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Just now',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Result Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF14201A),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: _buildPreview(),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor: _isLiveCameraMode
                                      ? const Color(0xFF4ADE80)
                                      : Colors.amber,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isLiveCameraMode ? 'Live' : 'Static',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        /* 
                        // Removed manual capture button
                        if (_isLiveCameraMode)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: FloatingActionButton(
                              mini: true,
                              backgroundColor: const Color(0xFF4ADE80),
                              onPressed: _captureAndClassify,
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        */
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detected Gesture',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            Text(
                              _detectedLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${(_confidence * 100).toStringAsFixed(1)}%',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4ADE80),
                              ),
                            ),
                            Text(
                              'Confidence',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _confidence,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF1E3A2F),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Supported Signs Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Supported Signs',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LibraryPage(),
                        ),
                      );
                    },
                    child: Text(
                      'View Library',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF4ADE80),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Supported Signs List
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSignCard(
                      'Letter A',
                      Icons.text_fields,
                      'assets/images/sign_language_a.png',
                    ),
                    const SizedBox(width: 12),
                    _buildSignCard(
                      'Letter B',
                      Icons.text_fields,
                      'assets/images/sign_language_b.png',
                    ),
                    const SizedBox(width: 12),
                    _buildSignCard(
                      'Letter C',
                      Icons.text_fields,
                      'assets/images/sign_language_c.png',
                    ),
                    const SizedBox(width: 12),
                    _buildSignCard(
                      'Letter D',
                      Icons.text_fields,
                      'assets/images/sign_language_d.png',
                    ),
                    const SizedBox(width: 12),
                    _buildSignCard(
                      'Letter E',
                      Icons.text_fields,
                      'assets/images/sign_language_e.png',
                    ),
                    const SizedBox(width: 12),
                    _buildSignCard(
                      'Letter L',
                      Icons.text_fields,
                      'assets/images/sign_language_l.png',
                    ),
                    const SizedBox(width: 12),
                    _buildSignCard(
                      'Letter O',
                      Icons.text_fields,
                      'assets/images/sign_language_o.png',
                    ),
                    const SizedBox(width: 12),
                    _buildSignCard(
                      'Letter S',
                      Icons.text_fields,
                      'assets/images/sign_language_s.png',
                    ),
                    const SizedBox(width: 12),
                    _buildSignCard(
                      'Letter U',
                      Icons.text_fields,
                      'assets/images/sign_language_u.png',
                    ),
                    const SizedBox(width: 12),
                    _buildSignCard(
                      'Letter Y',
                      Icons.text_fields,
                      'assets/images/sign_language_y.png',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80), // Extra space for FAB
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLiveCameraMode
          ? GestureDetector(
              onTap: () => _captureAndClassify(isManualCapture: true),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4ADE80),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt,
                      color: Color(0xFF0D1612), // Dark contrasting color
                      size: 36,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPreview() {
    if (_isLiveCameraMode) {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        return CameraPreview(_cameraController!);
      }
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
        ),
      );
    } else {
      if (_selectedImage != null) {
        return Image.file(_selectedImage!, fit: BoxFit.cover);
      }
      return Container(
        color: Colors.grey[900],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.white24,
            ),
            const SizedBox(height: 8),
            Text(
              'No image selected',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSignCard(String label, IconData icon, [String? assetPath]) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF14201A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: assetPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(assetPath, fit: BoxFit.cover),
                )
              : Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isCamera,
  }) {
    // Distinct styles based on type
    final Color backgroundColor = isCamera
        ? const Color(0xFF0F1E19)
        : const Color(0xFF2C2C2C);
    final Color accentColor = isCamera ? const Color(0xFF4ADE80) : Colors.white;

    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? accentColor : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Stack(
        children: [
          // Background Effects
          if (isCamera) const Positioned.fill(child: _RadarBackground()),
          if (!isCamera) const Positioned.fill(child: _GalleryBackground()),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Floating Icon Bubble
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCamera
                        ? const Color(0xFF4ADE80)
                        : Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: isCamera
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF4ADE80,
                              ).withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: isCamera ? Colors.black : Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isCamera ? const Color(0xFF4ADE80) : Colors.white54,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarBackground extends StatelessWidget {
  const _RadarBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RadarPainter());
  }
}

class _RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.4);
    final paint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw concentric circles
    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, i * 25.0, paint);
    }

    // Draw sweeping gradient/sector if desired, or simplified
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4ADE80).withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 100));

    canvas.drawCircle(center, 80, bgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GalleryBackground extends StatelessWidget {
  const _GalleryBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Simulated "Photo" rect
        Positioned(
          right: -20,
          top: -20,
          child: Transform.rotate(
            angle: 0.2,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  color: Colors.white.withValues(alpha: 0.05),
                  size: 64,
                ),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
