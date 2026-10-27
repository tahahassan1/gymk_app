/// Application safety bound: 201 deletes, verified against the installed SDK.
/// Fixed-size subscription fields and document paths keep the request bounded.
abstract final class MemberCascadeLimit {
  static const subscriptions = 200;
}
