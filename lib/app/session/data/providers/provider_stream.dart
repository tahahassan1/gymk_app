import 'dart:async';

import 'firebase_failure.dart';

/// Preserve SDK cancellation while mapping records and failures. Async
/// generators awaiting another snapshot can delay tenant listener teardown.
Stream<R> providerStream<S, R>(
  Stream<S> source,
  R Function(S) decode, {
  void Function()? onFailure,
}) => source
    .map(decode)
    .transform(
      StreamTransformer<R, R>.fromHandlers(
        handleError: (Object error, StackTrace trace, EventSink<R> sink) {
          onFailure?.call();
          sink.addError(firebaseFailure(error), trace);
        },
      ),
    );
