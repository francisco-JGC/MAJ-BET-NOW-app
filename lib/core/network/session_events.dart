import 'dart:async';

class SessionEvents {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onExpired => _controller.stream;

  void emitExpired() => _controller.add(null);

  Future<void> close() => _controller.close();
}
