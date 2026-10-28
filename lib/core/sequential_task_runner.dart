/// Runs asynchronous tasks one after another, in call order.
///
/// A failed task does not block the following ones; its error is still
/// returned to its own caller.
class SequentialTaskRunner {
  Future<void> _previousTask = Future.value();

  Future<void> run(Future<void> Function() task) {
    final thisTask = _previousTask.then((_) => task());
    // The chain must survive failures, which are reported through [thisTask].
    _previousTask = thisTask.then((_) {}, onError: (Object _) {});
    return thisTask;
  }
}
