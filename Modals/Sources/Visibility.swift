import UIKit

/// Represents the visibility of a view controller, in relation to the "appear" and "disappear"
/// lifecycle events.
///
/// This diagram shows the lifecycle of a view controller, and the events that occur between
/// each state:
///
/// ```
///                           ┌──────────────┐
///  viewWillAppear──────────▶│  Appearing   │────────────viewDidAppear
///         │                 └──────────────┘                  │
///         │                 ▲              │                  │
///         │                 │              │                  ▼
/// ┌──────────────┐          │      viewWillDisappear  ┌──────────────┐
/// │ Disappeared  │          │              │          │   Appeared   │
/// └──────────────┘   viewWillAppear        │          └──────────────┘
///         ▲                 │              │                  │
///         │                 │              ▼                  │
///         │                 ┌──────────────┐                  │
/// viewDidDisappear──────────│ Disappearing │◀───────viewWillDisappear
///                           └──────────────┘
/// ```
///
/// Implements `Comparable` in order of visibility, from the least visible to the most visible.
///
enum Visibility: Comparable, Equatable {
    case disappeared
    case disappearing
    case appearing
    case appeared

    /// Resolves a view controller's effective visibility when nested in another view
    /// controller.
    ///
    /// The resulting visibility is always the "least visible" of the two states. For example, a
    /// view controller that is `disappeared` will never be considered more visible by its
    /// container, nor will a container that is `disappeared` allow a child to appear more
    /// visible.
    func within(containerState: Visibility) -> Visibility {
        min(self, containerState)
    }
}
