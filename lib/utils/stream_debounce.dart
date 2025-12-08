import 'dart:async';

/// Extension to add debounce functionality to streams
extension StreamDebounce<T> on Stream<T> {
  /// Debounces the stream by the specified [duration].
  /// 
  /// Only emits an item from the stream if a particular timespan has passed
  /// without the stream emitting another item. This is useful for reducing
  /// the frequency of UI updates when listening to rapidly changing data.
  /// 
  /// Example:
  /// ```dart
  /// myStream.debounce(Duration(seconds: 3)).listen((data) {
  ///   // This will only be called once every 3 seconds at most
  ///   print(data);
  /// });
  /// ```
  Stream<T> debounce(Duration duration) {
    StreamController<T>? controller;
    Timer? debounceTimer;
    StreamSubscription<T>? subscription;
    T? lastValue;
    bool hasValue = false;

    void onData(T value) {
      lastValue = value;
      hasValue = true;
      
      // Cancel existing timer
      debounceTimer?.cancel();
      
      // Start new timer
      debounceTimer = Timer(duration, () {
        if (hasValue && controller != null && !controller.isClosed) {
          controller.add(lastValue as T);
          hasValue = false;
        }
      });
    }

    void onError(Object error, StackTrace stackTrace) {
      debounceTimer?.cancel();
      controller?.addError(error, stackTrace);
    }

    void onDone() {
      debounceTimer?.cancel();
      // Emit the last value if we have one
      if (hasValue && controller != null && !controller.isClosed) {
        controller.add(lastValue as T);
      }
      controller?.close();
    }

    controller = StreamController<T>(
      onListen: () {
        subscription = listen(
          onData,
          onError: onError,
          onDone: onDone,
        );
      },
      onPause: () {
        subscription?.pause();
        debounceTimer?.cancel();
      },
      onResume: () {
        subscription?.resume();
      },
      onCancel: () {
        debounceTimer?.cancel();
        return subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
