import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Service for preloading videos during app initialization.
/// Ensures videos are ready to play immediately when needed in the UI.
class VideoPreloaderService {
  VideoPlayerController? _portalVideoController;
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Path to the portal background video
  static const String portalVideoPath = 'assets/videos/background_loop.mp4';

  /// Get the preloaded portal video controller.
  /// Returns null if not yet initialized.
  VideoPlayerController? get portalVideoController => _portalVideoController;

  /// Whether the portal video is initialized and ready to play
  bool get isPortalVideoReady =>
      _isInitialized && _portalVideoController != null;

  /// Preload the portal video during splash screen.
  /// Can be called multiple times - will re-initialize if previously disposed.
  Future<void> preloadPortalVideo() async {
    // If already initializing, wait for it to complete
    if (_isInitializing) {
      debugPrint('[VideoPreloader] Already initializing, waiting...');
      // Wait for initialization to complete (max 5 seconds)
      for (var i = 0; i < 50; i++) {
        if (!_isInitializing) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    // If already initialized and ready, just return
    if (_isInitialized && _portalVideoController != null) {
      debugPrint('[VideoPreloader] Already initialized');
      return;
    }

    _isInitializing = true;

    try {
      debugPrint('[VideoPreloader] Starting video preload...');

      // Dispose old controller if exists
      if (_portalVideoController != null) {
        debugPrint('[VideoPreloader] Disposing old controller');
        await _portalVideoController!.dispose();
        _portalVideoController = null;
      }

      _portalVideoController = VideoPlayerController.asset(portalVideoPath);

      await _portalVideoController!.initialize();
      _portalVideoController!.setLooping(true);
      _portalVideoController!.setVolume(0.0);

      _isInitialized = true;
      _isInitializing = false;

      debugPrint('[VideoPreloader] Video preloaded successfully');
    } catch (e) {
      _isInitializing = false;
      _isInitialized = false;
      debugPrint('[VideoPreloader] Error preloading video: $e');

      // Dispose on error
      _portalVideoController?.dispose();
      _portalVideoController = null;
    }
  }

  /// Dispose the preloaded video controller.
  /// This should be called when the app is being disposed or when the video is no longer needed.
  void dispose() {
    debugPrint('[VideoPreloader] Disposing video controller');
    _portalVideoController?.dispose();
    _portalVideoController = null;
    _isInitialized = false;
    _isInitializing = false;
  }

  /// Reset the video to beginning (useful for replaying)
  Future<void> resetVideo() async {
    if (_portalVideoController != null && _isInitialized) {
      await _portalVideoController!.seekTo(Duration.zero);
    }
  }
}
