import 'dart:js_interop';

@JS('__fixCameraVideos')
external void _fixCameraVideos();

/// Web implementation that calls the window.__fixCameraVideos helper
void fixWebCameraVideos() {
  try {
    _fixCameraVideos();
  } catch (_) {
    // Graceful fallback
  }
}
