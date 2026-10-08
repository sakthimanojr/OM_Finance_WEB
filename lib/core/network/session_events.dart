import 'dart:async';

/// A simple global event bus for session lifecycle events.
///
/// [ApiClient] fires [onSessionExpired] when both the access token refresh
/// fails (i.e. the refresh token is also invalid/expired).
/// [AuthNotifier] subscribes to this stream and automatically logs the
/// user out, which in turn triggers GoRouter's redirect guard to navigate
/// to the login screen.
class SessionEvents {
  SessionEvents._();

  static final _controller = StreamController<void>.broadcast();

  /// Stream that emits when the session has expired and cannot be refreshed.
  static Stream<void> get onSessionExpired => _controller.stream;

  /// Call this to notify all listeners that the session has expired.
  static void notifyExpired() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
