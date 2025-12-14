import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _isRecording = false;
  
  File? _capturedImage;
  File? _recordedVideo;
  Position? _location;
  double _accelerometerX = 0;
  double _accelerometerY = 0;
  double _accelerometerZ = 0;
  double _lightLevel = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startSensorListeners();
    _requestLocationAsync();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission (mandatory)
    final cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      try {
        _cameras = await availableCameras();
        if (_cameras!.isNotEmpty) {
          _cameraController = CameraController(
            _cameras![0],
            ResolutionPreset.high,
            enableAudio: true, // Enable audio for video recording
          );
          await _cameraController!.initialize();
          if (mounted) {
            setState(() => _isCameraInitialized = true);
          }
        }
      } catch (e) {
        _showError('Camera initialization failed: $e');
      }
    } else {
      _showError('Camera permission is required to report issues');
    }
  }

  Future<void> _requestLocationAsync() async {
    // Request location permission asynchronously (non-blocking)
    try {
      final locationStatus = await Permission.location.request();
      if (locationStatus.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (mounted) {
          setState(() => _location = position);
        }
      }
      // If denied, we'll proceed without location - it's optional
    } catch (e) {
      // Location retrieval failed, but we continue
      debugPrint('Location error: $e');
    }
  }

  void _startSensorListeners() {
    // Accelerometer
    accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _accelerometerX = event.x;
          _accelerometerY = event.y;
          _accelerometerZ = event.z;
        });
      }
    });

    // Light sensor removed due to compatibility issues
    // Setting default light level
    _lightLevel = 500.0; // Default ambient light level
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      
      // Get location if not already available
      if (_location == null) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 10));
          setState(() => _location = position);
        } catch (e) {
          debugPrint('Failed to get location: $e');
          // Continue without location
        }
      }

      setState(() {
        _capturedImage = File(image.path);
        _recordedVideo = null; // Clear any previous video
      });
    } catch (e) {
      _showError('Failed to capture photo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.startVideoRecording();
      setState(() => _isRecording = true);
    } catch (e) {
      _showError('Failed to start video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final XFile video = await _cameraController!.stopVideoRecording();
      
      // Get location if not already available
      if (_location == null) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 10));
          setState(() => _location = position);
        } catch (e) {
          debugPrint('Failed to get location: $e');
          // Continue without location
        }
      }

      setState(() {
        _recordedVideo = File(video.path);
        _capturedImage = null; // Clear any previous image
        _isRecording = false;
      });
    } catch (e) {
      _showError('Failed to stop video recording: $e');
      setState(() => _isRecording = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitIssue() async {
    if ((_capturedImage == null && _recordedVideo == null)) {
      _showError('Please capture a photo or video first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Determine which media was captured
      final mediaFile = _capturedImage ?? _recordedVideo;
      final isVideo = _recordedVideo != null;

      // Use location if available, otherwise use default coordinates
      final lat = _location?.latitude ?? 26.9124; // Jaipur default
      final lon = _location?.longitude ?? 75.7873;

      // Detect issue with AI
      final detection = await ApiService().detectIssue(
        imageFile: mediaFile!,
        latitude: lat,
        longitude: lon,
        accelerometerX: _accelerometerX,
        accelerometerY: _accelerometerY,
        accelerometerZ: _accelerometerZ,
        lightLevel: _lightLevel,
      );

      // Show confirmation dialog
      if (mounted) {
        _showConfirmationDialog(detection, isVideo);
      }
    } catch (e) {
      _showError('Detection failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showConfirmationDialog(Map<String, dynamic> detection, bool isVideo) {
    final issueType = detection['detection']?['issue_type'] ?? 'unknown';
    final confidence = detection['detection']?['confidence'] ?? 0.0;
    final confidencePercent = (confidence * 100).toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Detection Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detected: ${IssueTypes.labels[issueType] ?? issueType}',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Confidence: $confidencePercent%',
              style: AppTextStyles.body1,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Media: ${isVideo ? 'Video' : 'Photo'}',
              style: AppTextStyles.body2,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Do you want to submit this issue?',
              style: AppTextStyles.body2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createIssue(detection['detection']['id']);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _createIssue(String detectionId) async {
    setState(() => _isLoading = true);

    try {
      await ApiService().createIssue(detectionId: detectionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Reset and navigate to home
        setState(() {
          _capturedImage = null;
          _recordedVideo = null;
        });
        
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showError('Failed to create issue: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _recordedVideo = null;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_capturedImage != null) {
      return _buildPhotoPreviewScreen();
    }

    if (_recordedVideo != null) {
      return _buildVideoPreviewScreen();
    }

    return _buildCameraScreen();
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Issue'),
        backgroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          // Camera Preview
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),

          // Sensor Data Overlay
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Card(
              color: Colors.black54,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS: ${_location?.latitude.toStringAsFixed(6) ?? "Getting..."}, ${_location?.longitude.toStringAsFixed(6) ?? "Getting..."}',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Motion: ${_accelerometerZ.toStringAsFixed(2)} m/s²',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Light: ${_lightLevel.toStringAsFixed(0)} lux',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Capture Button with Press-and-Hold for Video
          Positioned(
            bottom: AppSpacing.xl,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isLoading || _isRecording ? null : _capturePhoto,
                onLongPressStart: _isLoading ? null : (_) => _startVideoRecording(),
                onLongPressEnd: _isLoading ? null : (_) => _stopVideoRecording(),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Colors.red
                        : _isLoading
                            ? Colors.grey
                            : Colors.white,
                    border: Border.all(color: AppColors.primary, width: 4),
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : _isRecording
                          ? const Icon(Icons.stop, size: 32, color: Colors.white)
                          : const Icon(Icons.camera, size: 32),
                ),
              ),
            ),
          ),

          // Recording Timer
          if (_isRecording)
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'Recording...',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreviewScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Preview'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Image Preview
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Image.file(_capturedImage!),
              ),
            ),
          ),

          // Sensor Data
          Card(
            margin: const EdgeInsets.all(AppSpacing.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Captured Data:', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Location: ${_location?.latitude.toStringAsFixed(6) ?? "N/A"}, ${_location?.longitude.toStringAsFixed(6) ?? "N/A"}',
                    style: AppTextStyles.body2,
                  ),
                  Text(
                    'Accelerometer: X=${_accelerometerX.toStringAsFixed(2)}, Y=${_accelerometerY.toStringAsFixed(2)}, Z=${_accelerometerZ.toStringAsFixed(2)}',
                    style: AppTextStyles.body2,
                  ),
                  Text(
                    'Light Level: ${_lightLevel.toStringAsFixed(0)} lux',
                    style: AppTextStyles.body2,
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _retakePhoto,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitIssue,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreviewScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Preview'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Video Preview (placeholder - showing file info)
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam, size: 80, color: Colors.white),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Video Captured',
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Size: ${(_recordedVideo!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: AppTextStyles.body2.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sensor Data
          Card(
            margin: const EdgeInsets.all(AppSpacing.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Captured Data:', style: AppTextStyles.h3),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Location: ${_location?.latitude.toStringAsFixed(6) ?? "N/A"}, ${_location?.longitude.toStringAsFixed(6) ?? "N/A"}',
                    style: AppTextStyles.body2,
                  ),
                  Text(
                    'Accelerometer: X=${_accelerometerX.toStringAsFixed(2)}, Y=${_accelerometerY.toStringAsFixed(2)}, Z=${_accelerometerZ.toStringAsFixed(2)}',
                    style: AppTextStyles.body2,
                  ),
                  Text(
                    'Light Level: ${_lightLevel.toStringAsFixed(0)} lux',
                    style: AppTextStyles.body2,
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _retakePhoto,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitIssue,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Submit'),
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
