import 'dart:async';

/// Concatenates all of the specified stream sequences, as long as the
/// previous stream sequence terminated successfully.
///
/// It does this by subscribing to each stream one by one, emitting all items
/// and completing before subscribing to the next stream.
///
/// [Interactive marble diagram](http://rxmarbles.com/#concat)
///
/// ### Example
///
///     ConcatStream([
///       Stream.fromIterable([1]),
///       TimerStream(2, Duration(days: 1)),
///       Stream.fromIterable([3])
///     ])
///     .listen(print); // prints 1, 2, 3
class ConcatStream<T> extends Stream<T> {
  final StreamController<T> _controller;

  /// Constructs a [Stream] which emits all events from [streams].
  /// The [Iterable] is traversed upwards, meaning that the current first
  /// [Stream] in the [Iterable] needs to complete, before events from the
  /// next [Stream] will be subscribed to.
  ConcatStream(Iterable<Stream<T>> streams)
      : _controller = _buildController(streams);

  @override
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) =>
      _controller.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  static StreamController<T> _buildController<T>(Iterable<Stream<T>> streams) {
    if (streams == null) {
      throw ArgumentError('Streams cannot be null');
    } else if (streams.isEmpty) {
      throw ArgumentError('At least 1 stream needs to be provided');
    } else if (streams.any((Stream<T> stream) => stream == null)) {
      throw ArgumentError('One of the provided streams is null');
    }

    StreamController<T> controller;
    StreamSubscription<T> subscription;

    controller = StreamController<T>(
        sync: true,
        onListen: () {
          final len = streams.length;
          var index = 0;

          void moveNext() {
            var stream = streams.elementAt(index);
            subscription?.cancel();

            subscription = stream.listen(controller.add,
                onError: controller.addError, onDone: () {
              index++;

              if (index == len) {
                controller.close();
              } else {
                moveNext();
              }
            });
          }

          moveNext();
        },
        onPause: ([Future<dynamic> resumeSignal]) =>
            subscription?.pause(resumeSignal),
        onResume: () => subscription?.resume(),
        onCancel: () => subscription.cancel());

    return controller;
  }
}
