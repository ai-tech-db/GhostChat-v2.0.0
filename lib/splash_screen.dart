import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/branding/Ghost-Chat.mp4')
      ..initialize().then((_) {
        _controller.play();
        _controller.setVolume(0);
        _controller.addListener(_onVideoProgress);
        setState(() {});
        // Fallback: se dopo 8 secondi il video non è finito, passa comunque
        _fallbackTimer = Timer(const Duration(seconds: 8), _goToNext);
      }).catchError((error) {
        debugPrint('Video init error: $error');
        _goToNext();
      });
  }

  void _onVideoProgress() {
    if (_controller.value.isCompleted) {
      _goToNext();
    }
  }

  void _goToNext() {
    _fallbackTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.nextScreen),
      );
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller.removeListener(_onVideoProgress);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
