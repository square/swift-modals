import WorkflowUI


/// A `ToastContainer` which has `AnyScreen` for both its base, and modals.
public typealias AnyToastContainer = ToastContainer<AnyScreen, AnyScreen>


/// Use a `ToastContainer` to render a base screen and an array of toasts on top of it.
///
/// When toasts are added or removed from a container, the screen will animate the changes based on the toasts keys. If
/// new toasts are added, a presentation animation will occur, and if toasts are removed, a dismissal animation will
/// occur. Existing toasts will have their screens updated.
///
/// This container uses the modal system to trampoline toasts to a [ModalHost](x-source-tag://ModalHost),
/// which must be installed somewhere in your hierarchy. In a pure workflow application, you should install a
/// [ModalHostContainer](x-source-tag://ModalHostContainer) at the root of your app. In a hybrid application, you should
/// install a [ModalHostContainerViewController](x-source-tag://ModalHostContainerViewController) instead, in which case
/// you do not need to use a `ModalHostContainer`.
///
/// Note that toasts are updated asynchronously, so this container won't present or dismiss toasts synchronously during
/// the screen update of a workflow render.
///
/// - Tag: ToastContainer
///
public struct ToastContainer<BaseContent, ToastContent> {

    /// The screen to render behind the toasts. If there are no toasts in the `modal` array, this screen will be
    /// rendered by the container.
    ///
    public var base: BaseContent

    public var toasts: [Toast<ToastContent>]

    /// Create a toast container with a base screen and the additional provided toasts.
    ///
    /// ```
    /// ToastContainer(
    ///     base: MyRootScreen(),
    ///     toasts: [
    ///         state.shouldShowToast
    ///              ? self.toast(...)
    ///              : nil
    ///     ].compactMap { $0 }
    /// )
    /// ```
    ///
    public init(
        base: BaseContent,
        toasts: [Toast<ToastContent>]
    ) {
        self.base = base
        self.toasts = toasts
    }

    /// Create a toast container with a base screen and array of toasts.
    ///
    public init(
        base: () -> BaseContent,
        @Builder<Toast<ToastContent>> toasts: () -> [Toast<ToastContent>] = { [] }
    ) {
        self.base = base()
        self.toasts = toasts()
    }
}


extension Screen {

    /// Create a toast container with the screen as the base screen and the additional provided toasts.
    ///
    /// ```
    /// myScreen.presentingToasts {
    ///     if self.showingToast {
    ///         self.toast(...)
    ///     }
    /// }
    /// ```
    ///
    public func presentingToasts<ToastContent: Screen>(
        @Builder<Toast<ToastContent>> _ toasts: () -> [Toast<ToastContent>]
    ) -> ToastContainer<Self, ToastContent> {
        ToastContainer(base: self, toasts: toasts())
    }
}


extension ToastContainer: Screen where BaseContent: Screen, ToastContent: Screen {

    public func viewControllerDescription(environment: ViewEnvironment) -> ViewControllerDescription {
        AnyModalToastContainerViewController.description(
            for: asAnyModalToastContainer(),
            environment: environment,
            performInitialUpdate: false
        )
    }

    /// Type erases the toast content for display in `AnyModalContainerViewController`.
    ///
    func asAnyModalToastContainer() -> AnyModalToastContainer {
        AnyModalToastContainer(
            base: base.asAnyScreen(),
            modals: [],
            toasts: toasts.map { $0.asAnyScreenToast() }
        )
    }
}

extension ToastContainer: SingleScreenContaining where BaseContent: Screen {

    public var primaryScreen: Screen {
        // toasts do not represent a new "screen" semantically so we always return the base
        base
    }
}
