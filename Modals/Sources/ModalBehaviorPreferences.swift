import UIKit

/// Modal behavior preferences are used by the modal presentation system to configure certain
/// behaviors, such as whether tap to dismiss is enabled.
///
public struct ModalBehaviorPreferences {

    /// The type of interactive dismiss.
    public enum InteractiveDismissBehavior {
        /// There is no interactive dismiss.
        case disabled

        /// Swiping down will interactively dismiss the modal.
        ///
        /// Dismiss the modal in the `onDismiss` closure. Not doing so may result in undefined behavior.
        /// Note that `onDismiss` is called after the dismiss interaction and animation completes.
        case swipeDown(onDismiss: () -> Void)

        var onDismiss: (() -> Void)? {
            switch self {
            case .disabled:
                nil
            case .swipeDown(let onSwipe):
                onSwipe
            }
        }
    }

    /// Behavior for when the overlay of the modal is tapped.
    public enum OverlayTapBehavior {
        /// Tapping the overlay will do nothing.
        case disabled

        /// Tapping the overlay will dismiss the modal.
        ///
        /// Dismiss the modal in the `onDismiss` closure.
        /// Not doing so may result in undefined behavior.
        case dismiss(onDismiss: () -> Void)

        /// Pass through touches in the overlay through to layers below the modal.
        case passThrough

        /// Perform a custom action when the overlay is tapped.
        case tap(onTap: () -> Void)

        var onDismiss: (() -> Void)? {
            switch self {
            case .disabled, .passThrough, .tap:
                nil
            case .dismiss(let onDismiss):
                onDismiss
            }
        }
    }

    /// A collection of preferences that determine whether various view controller containment preferences will be
    /// provided by the modal content view controller.
    public struct ViewControllerContainmentPreferences {
        /// Indicates whether the content presented by this modal should provide supported interface orientations to the
        /// modal host.
        ///
        /// If this property's value is `false` and another modal is presented behind this modal with a style whose
        /// corresponding value is `true`, that modal's content will provide values for this preference, otherwise
        /// the modal hosts's content view controller will be used.
        public var providesSupportedInterfaceOrientations: Bool

        /// Indicates whether the content presented by this modal should provide the status bar appearance information
        /// to the modal host.
        ///
        /// This includes:
        /// - `childForStatusBarStyle`
        /// - `childForStatusBarHidden`
        /// - `preferredStatusBarUpdateAnimation`
        ///
        /// If this property's value is `false` and another modal is presented behind this modal with a style whose
        /// corresponding value is `true`, that modal's content will provide values for this preference, otherwise
        /// the modal hosts's content view controller will be used.
        public var providesStatusBarAppearance: Bool

        /// Indicates whether the content presented by this modal should provide the home indicator hidden preference to
        /// the modal host.
        ///
        /// If this property's value is `false` and another modal is presented behind this modal with a style whose
        /// corresponding value is `true`, that modal's content will provide values for this preference, otherwise
        /// the modal hosts's content view controller will be used.
        public var providesHomeIndicatorAutoHidden: Bool

        /// Indicates whether the content presented by this modal should provide the screen edges deferring system
        /// gestures preference to the modal host.
        ///
        /// If this property's value is `false` and another modal is presented behind this modal with a style whose
        /// corresponding value is `true`, that modal's content will provide values for this preference, otherwise
        /// the modal hosts's content view controller will be used.
        public var providesScreenEdgesDeferringSystemGestures: Bool

        /// Indicates whether the content presented by this modal should provide the pointer lock preference to the
        /// modal host.
        ///
        /// If this property's value is `false` and another modal is presented behind this modal with a style whose
        /// corresponding value is `true`, that modal's content will provide values for this preference, otherwise
        /// the modal hosts's content view controller will be used.
        public var providesPointerLock: Bool

        /// A collection of preferences that determine whether various view controller containment preferences will be
        /// provided by the modal content view controller.
        ///
        /// If a property's value is `false` and another modal is presented behind this modal with a style whose
        /// corresponding value is `true`, that modal's content will provide values for this preference, otherwise
        /// the modal hosts's content view controller will be used.
        ///
        /// - Parameters:
        ///   - providesSupportedInterfaceOrientations: Indicates whether the content presented by this modal should
        ///     provide supported interface orientations to the modal host.
        ///   - providesStatusBarAppearance: Indicates whether the content presented by this modal should provide the
        ///     status bar appearance to the modal host.
        ///   - providesHomeIndicatorAutoHidden: Indicates whether the content presented by this modal should provide
        ///     the home indicator hidden preference to the modal host.
        ///   - providesScreenEdgesDeferringSystemGestures: Indicates whether the content presented by this modal should
        ///     provide the screen edges deferring system gestures preference to the modal host.
        ///   - providesPointerLock: Indicates whether the content presented by this modal should provide the pointer
        ///     lock preference to the modal host.
        public init(
            providesSupportedInterfaceOrientations: Bool,
            providesStatusBarAppearance: Bool,
            providesHomeIndicatorAutoHidden: Bool,
            providesScreenEdgesDeferringSystemGestures: Bool,
            providesPointerLock: Bool
        ) {
            self.providesSupportedInterfaceOrientations = providesSupportedInterfaceOrientations
            self.providesStatusBarAppearance = providesStatusBarAppearance
            self.providesHomeIndicatorAutoHidden = providesHomeIndicatorAutoHidden
            self.providesScreenEdgesDeferringSystemGestures = providesScreenEdgesDeferringSystemGestures
            self.providesPointerLock = providesPointerLock
        }

        /// No preferences not provided to the modal host.
        public static var provideNone: Self {
            .init(
                providesSupportedInterfaceOrientations: false,
                providesStatusBarAppearance: false,
                providesHomeIndicatorAutoHidden: false,
                providesScreenEdgesDeferringSystemGestures: false,
                providesPointerLock: false
            )
        }

        /// All preferences are provided to the modal host.
        public static var provideAll: Self {
            .init(
                providesSupportedInterfaceOrientations: true,
                providesStatusBarAppearance: true,
                providesHomeIndicatorAutoHidden: true,
                providesScreenEdgesDeferringSystemGestures: true,
                providesPointerLock: true
            )
        }

        // All preferences are provided to the modal host except for supported interface orientations.
        public static var provideAllButSupportedInterfaceOrientations: Self {
            .init(
                providesSupportedInterfaceOrientations: false,
                providesStatusBarAppearance: true,
                providesHomeIndicatorAutoHidden: true,
                providesScreenEdgesDeferringSystemGestures: true,
                providesPointerLock: true
            )
        }

        /// The default view controller containment preferences.
        public static var `default`: Self { .provideNone }
    }

    /// The overlay tap behavior for the modal.
    public var overlayTap: OverlayTapBehavior

    /// The source view of the modal in which touches are passed through to.
    public var sourceView: UIView?

    /// The interactive dismiss behavior for the modal.
    public var interactiveDismiss: InteractiveDismissBehavior

    /// Whether the style requires the `preferredContentSize` of the content view controller in order to layout the
    /// modal's container.
    ///
    /// If your style's frame size is not dependent on the size of the content in the modal, you can improve performance
    /// by setting this to `false`.
    public var usesPreferredContentSize: Bool

    /// Indicates that this modal style's display values may change between layouts even if the
    /// content does not. This will opt-in the modal to layout every time the presenting modal host
    /// is laid out. For performance reasons this is `false` by default. You may want to enable this
    /// for styles that are anchored when you expect the anchor to move or resize between layouts.
    public var needsLayoutOnPresentationLayout: Bool

    /// Whether touches should pass through the modal content.
    public var passThroughContentTouches: Bool

    /// Whether the modal responds to changes to the keyboard frame.
    public var adjustsForKeyboard: Bool

    /// A collection of preferences that determine whether various view controller containment preferences will be
    /// provided by the modal content view controller.
    public var viewControllerContainmentPreferences: ViewControllerContainmentPreferences

    /// Whether the modal should resign the existing first responder when presented.
    public var resignsExistingFirstResponder: Bool

    /// Create some preferences.
    public init(
        overlayTap: OverlayTapBehavior = .disabled,
        sourceView: UIView? = nil,
        interactiveDismiss: InteractiveDismissBehavior = .disabled,
        usesPreferredContentSize: Bool,
        needsLayoutOnPresentationLayout: Bool = false,
        passThroughContentTouches: Bool = false,
        adjustsForKeyboard: Bool = false,
        viewControllerContainmentPreferences: ViewControllerContainmentPreferences = .provideNone,
        resignsExistingFirstResponder: Bool = true
    ) {
        self.overlayTap = overlayTap
        self.sourceView = sourceView
        self.interactiveDismiss = interactiveDismiss
        self.usesPreferredContentSize = usesPreferredContentSize
        self.needsLayoutOnPresentationLayout = needsLayoutOnPresentationLayout
        self.passThroughContentTouches = passThroughContentTouches
        self.adjustsForKeyboard = adjustsForKeyboard
        self.viewControllerContainmentPreferences = viewControllerContainmentPreferences
        self.resignsExistingFirstResponder = resignsExistingFirstResponder
    }
}
