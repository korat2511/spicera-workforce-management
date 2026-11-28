import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/utils/snackbar_utils.dart';
import 'attendance_pin_sheet.dart';

/// First step of the kiosk attendance flow: an in-app front-camera capture
/// (not the OS camera app) so framing/instructions stay under our control.
class AttendanceCameraScreen extends StatefulWidget {
  const AttendanceCameraScreen({super.key});

  @override
  State<AttendanceCameraScreen> createState() => _AttendanceCameraScreenState();
}

class _AttendanceCameraScreenState extends State<AttendanceCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  String? _error;
  bool _isCapturing = false;
  bool _showFlash = false;
  File? _capturedPhoto;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    setState(() => _error = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera is available on this device.');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      final initializeFuture = controller.initialize();
      setState(() {
        _controller = controller;
        _initializeFuture = initializeFuture;
      });
      await initializeFuture;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not access the camera. Please check camera permissions '
            'for this app.';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedPhoto = File(file.path);
        _showFlash = true;
      });
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _showFlash = false);
      });
    } catch (_) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        'Could not capture photo. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _retake() {
    setState(() => _capturedPhoto = null);
  }

  Future<void> _confirmPhoto() async {
    final photo = _capturedPhoto;
    if (photo == null) return;
    await showAttendancePinSheet(context, photo: photo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onPrimary),
        title: Text(
          _capturedPhoto == null ? 'Mark Attendance' : 'Review Photo',
          style: AppTypography.titleMd(color: AppColors.onPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => NavigationUtils.pop(null, context),
        ),
      ),
      body: SafeArea(
        child: _capturedPhoto == null ? _buildCaptureBody() : _buildReviewBody(),
      ),
    );
  }

  Widget _buildCaptureBody() {
    return Stack(
      children: [
        Positioned.fill(child: _buildCameraArea()),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.xl,
          child: Column(
            children: [
              Text(
                'Position your face within the frame',
                style: AppTypography.bodyLg(color: AppColors.onPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              _CaptureButton(onTap: _capture, isBusy: _isCapturing),
            ],
          ),
        ),
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _showFlash ? 1 : 0,
            duration: const Duration(milliseconds: 100),
            child: Container(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewBody() {
    final photo = _capturedPhoto!;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.file(photo, fit: BoxFit.cover),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.xl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Use this photo for your attendance record?',
                  style: AppTypography.bodyLg(color: AppColors.onPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _retake,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onPrimary,
                          side: const BorderSide(color: AppColors.onPrimary),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.base,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retake'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _confirmPhoto,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text('Use This Photo'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraArea() {
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _setupCamera);
    }

    final controller = _controller;
    if (controller == null) {
      return const _CameraLoadingState();
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _CameraLoadingState();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
            const Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: CustomPaint(painter: _DashedCirclePainter()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter();

  static const _dashLength = 12.0;
  static const _gapLength = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onPrimary.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final circumference = 2 * math.pi * radius;
    final dashCount = (circumference / (_dashLength + _gapLength)).floor();
    final dashAngle = _dashLength / radius;
    final gapAngle = _gapLength / radius;

    var startAngle = -math.pi / 2;
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) => false;
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onTap, required this.isBusy});

  final VoidCallback onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.onPrimary.withValues(alpha: 0.2),
          border: Border.all(color: AppColors.onPrimary, width: 3),
        ),
        child: isBusy
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.onPrimary),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onPrimary,
                ),
              ),
      ),
    );
  }
}

class _CameraLoadingState extends StatelessWidget {
  const _CameraLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.onPrimary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Starting camera...',
            style: AppTypography.bodyMd(color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: AppColors.onPrimary,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyLg(color: AppColors.onPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onPrimary,
                side: const BorderSide(color: AppColors.onPrimary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.base),
                ),
              ),
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
