/// Repository metadata, independent of Firebase snapshots and widget types.
final class ReadSnapshot<T> {
  const ReadSnapshot({
    required this.data,
    required this.fromCache,
    required this.hasPendingWrites,
    required this.isComplete,
  });

  final T data;
  final bool fromCache;
  final bool hasPendingWrites;

  /// Full-query server confirmation in this repository lifetime, never inferred
  /// from an empty cache or remembered durably across cold starts.
  final bool isComplete;

  ReadSnapshot<T> asIncomplete() => ReadSnapshot(
    data: data,
    fromCache: fromCache,
    hasPendingWrites: hasPendingWrites,
    isComplete: false,
  );
}
