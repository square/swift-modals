# Host-Owned Toast Presentation

> **Status: 🚧 Working draft — not a final proposal.**
> This document exists to frame a design conversation. Every API sketch below is
> illustrative, not a commitment; open questions outnumber settled answers. Comment freely,
> disagree loudly.

- Author: Rob MacEachern (with AI assistance)
- Tracking: [#13](https://github.com/square/swift-modals/pull/13) (near-term accessor),
  [squareup/market#12597](https://github.com/squareup/market/pull/12597) (motivating consumer)

## Summary

Toasts are currently modeled as a flavor of modal: owned by a presenting view controller,
displayed only while that view controller is aggregated, and kept alive by a
must-retain `ModalLifetime` token. Their intended semantics — transient, fire-and-forget,
app-level notifications — fit none of those mechanics. This document proposes making
imperative toast presentation **host-owned and best-effort**: the host owns presentation
state directly, retains it until dismissal, and treats a missing host as a defined no-op
rather than a fatal error. The declarative (Workflow rendering) path is unchanged.

## Problems with the current model

Each of these is observable in production code today:

1. **Toast lifetime is coupled to the presenting view controller.** A toast lives in the
   presenter's trampoline and is displayed only while that view controller remains in the
   host's aggregation tree. The canonical toast flows — "Item deleted" while navigating
   back, "Saved" as a sheet closes — are exactly the cases this cannot express. The
   standing workaround is "hoist it upwards," which each team reimplements differently
   (or asks about in Slack).

2. **The lifetime token is a footgun for toasts.** `ToastPresenter.present` returns a
   `ModalLifetime` that must be retained; releasing it dismisses the toast. The documented
   pattern retains it on the presenting view controller — silently re-coupling the toast
   to the screen the caller was trying to outlive. For modals, explicit lifetime ownership
   is a deliberate and good design; for fire-and-forget notifications it is accidental
   complexity.

3. **Failure is a crash or silence.** Presenting from a detached view controller hits
   `ModalHostAsserts.ensureModalHost`, which `fatalError`s in debug *and release* — the
   Modals FAQ documents teams hitting this. The common defense, `[weak self]` capture,
   converts the crash into an unlogged nothing. Neither outcome fits a notification whose
   failure leaves no undefined state behind.

4. **Consumers reconstruct host internals to escape 1–3.** MarketSwiftUI's toast presenter
   (squareup/market#12597) walks the view controller hierarchy and detects internal
   container types by module name to find a long-lived presentation point, and maintains
   its own retention store to defuse the token footgun. #13 (`HostToastPresenting`)
   removes the worst of that, but by *accessing* the current model rather than fixing it.

5. **Cross-platform divergence.** Market's Android (`toastService`) and web
   (`marketToasts`) toast APIs are ambient services whose presentations never depended on
   the triggering view. iOS is the outlier, for mechanical rather than semantic reasons.

## Design tenets

1. **Toasts are host-owned notifications, not aggregated modals.** Imperative
   presentation appends to state the host owns. Display does not depend on any presenting
   view controller's hierarchy position — there is no presenting view controller in the
   model.
2. **Retention is the host's job.** The returned handle is for *control* (dismiss,
   update, inspect), not life support. Dropping it changes nothing.
3. **Presentation is best-effort with defined failure.** No reachable host means a
   defined no-op plus a runtime warning — never `fatalError`. Modals keep their
   guaranteed-or-crash contract; the split is principled: a failed modal leaves undefined
   pending state, a failed toast leaves nothing.
4. **Environment and attribution travel with the call.** The presentation captures the
   presenter's `ViewEnvironment` (themes must come from where the toast was requested, not
   from whatever the host inherits — see the theming defect fixed in
   squareup/market#12597) and an optional source descriptor, restoring the debuggability
   that hierarchy ownership used to provide for free.
5. **The declarative path is untouched.** Workflow-rendered toasts remain
   rendering-derived and screen-scoped by design. Two models, each honest: state-driven
   (declarative) and event-driven (imperative, host-owned).

## Sketch (illustrative only)

```swift
/// A modal host that can display host-owned toasts.
public protocol ToastPresentingHost: AnyObject {

    /// Presents a toast owned by this host. The host retains the presentation until it is
    /// dismissed by its style's behaviors (timed or interactive dismissal) or via the
    /// returned handle. Dropping the handle does not dismiss the toast.
    @discardableResult
    func presentToast(
        _ viewController: UIViewController,
        style: ToastPresentationStyleProvider,
        accessibilityAnnouncement: String,
        environment: ViewEnvironment,       // captured at the call site
        source: ToastSource?                // optional attribution for debugging
    ) -> PresentedToast
}

/// A control handle. Not a lifetime token: deallocating it has no effect.
public protocol PresentedToast: AnyObject {
    var isPresented: Bool { get }
    func dismiss()
}

extension UIViewController {
    /// The nearest host able to display host-owned toasts, or nil (best-effort callers
    /// no-op; see Failure semantics).
    public var toastPresentingHost: ToastPresentingHost? { get }
}
```

Display-side, both hosts merge host-owned presentations with aggregated (declarative)
toasts when updating their existing `ToastPresentationViewController`:

```swift
toastPresentation.update(
    toasts: aggregated.toasts + ownedToasts.map(\.presentable),
    ...
)
```

A SwiftUI root-anchor installer (an environment key + modifier that locates
`toastPresentingHost`) likely belongs here too, so SwiftUI consumers need no UIKit
bridging of their own — this generalizes machinery currently private to MarketSwiftUI.

## Semantics to settle

These are the load-bearing decisions; the sketch above deliberately does not settle them.

- **Scoping.** Host-owned toasts are presented *at* a specific host and bypass
  presentation filters (you chose the host; nothing forwards). Callers reach a host via
  the accessor, which resolves… the nearest host? The root host? A policy parameter? The
  root is the likely default for notification semantics, but scoped panes (multi-window,
  split-screen POS) may want nearest.
- **Exactly-once dismissal.** Every dismissal path (timed, interactive, programmatic,
  host teardown) must funnel to a single idempotent completion, and `onDismiss`-style
  callbacks must fire even when the host is torn down with toasts live. Market's
  presenter implements this contract consumer-side today; it belongs in the framework.
- **Environment updates.** Is the captured `ViewEnvironment` a snapshot (toasts are
  short-lived; simple) or live-updating (correct across trait changes — dark mode,
  size classes — for indefinite-duration toasts)? Snapshot-with-trait-passthrough may be
  the pragmatic middle.
- **Queueing and policy.** Host-owned state is the natural seat for max-visible,
  coalescing, and dedup policies (parity with Android's toast service). Out of scope for
  a first pass, but the API shape should not preclude it.
- **ObjC exposure.** `ToastPresentationStyleProvider` and `ViewEnvironment` are not
  `@objc`-representable; is an ObjC shim needed, or is Swift-only acceptable (matching
  the existing `ToastPresenter`)?

## Migration

Deliberately incremental; every intermediate step is deletable:

1. **Now:** #13's `HostToastPresenting.contentToastPresenter` gives consumers a
   supported way to present long-lived toasts without walking host internals. Semantics
   are identical to content-presented toasts; no behavior change.
2. **This design lands:** `contentToastPresenter` is reimplemented atop `presentToast`
   (or deprecated in its favor). MarketSwiftUI deletes its retention store and owner
   resolution; its handle maps 1:1 to `PresentedToast`.
3. **Later:** queueing/dedup policies, and migration guidance for direct
   `toastPresenter.present` call sites that actually wanted screen-scoped toasts (they
   keep working unchanged — screen-scoped remains a valid, supported model).

## Alternatives considered

- **Status quo + #13 only.** Consumers get a supported access point but the token
  footgun, fatal failure mode, and consumer-side retention stores remain. Workable —
  this document argues it should not be the end state.
- **Host aggregates its own trampoline.** Functional for `host.toastPresenter` in ~2
  lines, but resurrects currently black-holed presentations on upgrade, resolves
  environment from the wrong place, implicitly legitimizes host-level *modals*, and needs
  a defined path through presentation-filter forwarding. Rejected in #13's design notes.
- **App-installed root anchors.** Each app hoists its own presentation point. Works
  today in UIKit apps; not implementable uniformly where the host's content is internal
  (WorkflowModals), and produces N divergent copies of the same machinery.
- **Window-level toast overlay.** Escapes the hierarchy entirely, but re-introduces the
  multi-window orchestration problems the original Modals design explicitly rejected
  (see "Window-contained modal container" in the Market iOS Modals design doc).

## References

- Modals README, Design section (aggregation model and its tenets)
- Market iOS Modals design doc (original architecture and rejected alternatives)
- [#13](https://github.com/square/swift-modals/pull/13) — `HostToastPresenting` accessor
- [squareup/market#12597](https://github.com/squareup/market/pull/12597) — MarketSwiftUI
  toast presenter: motivating consumer, including the theming and lifetime lessons above
- [squareup/market#12600](https://github.com/squareup/market/pull/12600) — end-state
  integration of #13, demonstrating what consumers delete
