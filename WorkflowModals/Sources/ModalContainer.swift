import Modals
import UIKit
import WorkflowUI


/// A `ModalContainer` which has `AnyScreen` for both its base, and modals.
public typealias AnyModalContainer = ModalContainer<AnyScreen, AnyScreen>

/// Use a `ModalContainer` to render a base screen and an array of modals on top of it.
///
/// When modals are added or removed from a container, the screen will animate the changes based on
/// the modals keys. If new modals are added, a presentation animation will occur, and if modals are
/// removed, a dismissal animation will occur. Existing modals will have their screens updated.
///
/// This container uses the modal system to trampoline modals to a
/// [ModalHost](x-source-tag://ModalHost), which must be installed somewhere in your hierarchy.
/// In a pure workflow application, you should install a
/// [ModalHostContainer](x-source-tag://ModalHostContainer) at the root of your app.
/// In a hybrid application, you should install a
/// [ModalHostContainerViewController](x-source-tag://ModalHostContainerViewController) instead,
/// in which case you do not need to use a `ModalHostContainer`.
///
/// Note that modals are updated asynchronously, so this container won't present or dismiss modals
/// synchronously during the screen update of a workflow render.
///
/// - Tag: ModalContainer
///
public struct ModalContainer<BaseContent, ModalContent> {

    /// The screen to render behind the modals. If there are no modals in the `modal` array, this
    /// screen will be rendered by the container.
    public var base: BaseContent

    /// An array of modals to present over the base.
    ///
    /// Screens must be wrapped in the `ModalContent` type, which tells the container how to style
    /// the presented modals. Ensure that each modal has a unique key as well.
    public var modals: [Modal<ModalContent>]

    /// Create a modal container with a base screen and array of modals.
    public init(
        base: BaseContent,
        modals: [Modal<ModalContent>] = []
    ) {
        self.base = base
        self.modals = modals
    }

    /// Create a modal container with a base screen and the additional provided modals.
    ///
    /// ```
    /// ModalContainer {
    ///     MyRootScreen()
    /// } modals: {
    ///     if self.showingModal {
    ///         self.partialModal(...)
    ///     }
    /// }
    /// ```
    public init(
        base: () -> BaseContent,
        @Builder<Modal<ModalContent>> modals: () -> [Modal<ModalContent>] = { [] }
    ) {
        self.base = base()
        self.modals = modals()
    }
}


extension Screen {

    /// Create a modal container with the screen as the base screen and the additional provided modals.
    ///
    /// ```
    /// myScreen.presentingModals {
    ///     if self.showingModal {
    ///         self.partialModal(...)
    ///     }
    /// }
    /// ```
    public func presentingModals<ModalContent: Screen>(
        @Builder<Modal<ModalContent>> _ modals: () -> [Modal<ModalContent>]
    ) -> ModalContainer<Self, ModalContent> {
        ModalContainer(base: self, modals: modals())
    }
}


extension ModalContainer: Screen where BaseContent: Screen, ModalContent: Screen {
    public func viewControllerDescription(environment: ViewEnvironment) -> ViewControllerDescription {
        AnyModalToastContainerViewController.description(
            for: asAnyModalToastContainer(),
            environment: environment,
            performInitialUpdate: false
        )
    }

    /// Type erases the model content for display in `AnyModalContainerViewController`.
    func asAnyModalToastContainer() -> AnyModalToastContainer {
        AnyModalToastContainer(
            base: base.asAnyScreen(),
            modals: modals.map { $0.asAnyScreenModal() },
            toasts: []
        )
    }
}

extension ModalContainer: SingleScreenContaining where BaseContent: Screen, ModalContent: Screen {

    public var primaryScreen: Screen {
        modals.last?.content ?? base
    }
}
