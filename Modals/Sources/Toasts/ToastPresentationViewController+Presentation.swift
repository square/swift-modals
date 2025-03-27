import UIKit


extension ToastPresentationViewController {

    /// Holds all the active references for a toast that is currently being presented.
    ///
    /// Each toast is contained in a few views to provide chrome and clipping, which results in a view hierarchy similar
    /// to the following diagram.
    ///
    /// ```
    /// Root View
    /// ├─Shadow View
    /// │ └─Clipping View
    /// │   └─Toast
    /// ├─Shadow View
    /// │ └─Clipping View
    /// │   └─Toast
    /// └─Shadow View
    ///   └─Clipping View
    ///     └─Toast
    /// ```
    ///
    final class Presentation {

        let viewController: UIViewController

        /// This view contains all other views and acts as the shadow-projecting view.
        /// Its frame matches the Toast content view.
        ///
        /// ### Note
        /// This value is intentionally lazy, so that we can call `theParentVC.addChild(viewController)`
        /// _before_ this view is loaded. Eg, ensuring that the view controller hierarchy is set up
        /// before our managed view controller recieves `loadView` or `viewDidLoad`.
        private(set) lazy var containerView: ShadowView = {
            let view = ShadowView(content: viewController.view)
            view.addGestureRecognizer(panGesture)

            return view
        }()

        let panGesture: UIPanGestureRecognizer

        var style: ToastPresentationStyle

        var state: TransitionState {
            willSet {
                guard let animator = state.animator,
                      animator != newValue.animator
                else {
                    return
                }

                animator.stopAnimationIfNeeded(withoutFinishing: true)
            }
        }

        var accessibilityAnnouncement: String

        var autoDismissTimer: Timer?

        var autoDismissDelay: TimeInterval? = nil

        // The time in which this presentation finished transitioning in.
        var displayStartTime: Date? = nil

        var creationTime: CFTimeInterval

        init(
            viewController: UIViewController,
            style: ToastPresentationStyle,
            state: TransitionState,
            accessibilityAnnouncement: String,
            creationTime: CFTimeInterval = CACurrentMediaTime()
        ) {
            self.viewController = viewController
            panGesture = UIPanGestureRecognizer()
            self.style = style
            self.state = state
            self.accessibilityAnnouncement = accessibilityAnnouncement
            self.creationTime = creationTime
        }

        deinit {
            state.animator?.stopAnimationIfNeeded(withoutFinishing: true)
        }
    }

    enum TransitionState {

        struct Interaction {
            var animator: UIViewPropertyAnimator
            var initialVerticalOffset: CGFloat
        }

        case pending
        case entering(UIViewPropertyAnimator)
        case interactiveDismiss(Interaction)
        case interactiveInverse(Interaction)
        case updating(UIViewPropertyAnimator)
        case presented
        case transitioningSize
        case pendingExit
        case exiting(UIViewPropertyAnimator)

        var isExiting: Bool {
            switch self {
            case .exiting,
                 .pendingExit:
                true

            case .pending,
                 .entering,
                 .updating,
                 .presented,
                 .transitioningSize,
                 .interactiveDismiss,
                 .interactiveInverse:
                false
            }
        }

        var interaction: Interaction? {
            switch self {
            case .interactiveDismiss(let interaction),
                 .interactiveInverse(let interaction):
                interaction

            case .pending,
                 .entering,
                 .transitioningSize,
                 .updating,
                 .pendingExit,
                 .exiting,
                 .presented:
                nil
            }
        }

        var animator: UIViewPropertyAnimator? {
            switch self {
            case .interactiveDismiss(let interaction),
                 .interactiveInverse(let interaction):
                interaction.animator

            case .entering(let animator),
                 .updating(let animator),
                 .exiting(let animator):
                animator

            case .pending,
                 .transitioningSize,
                 .pendingExit,
                 .presented:
                nil
            }
        }
    }
}
