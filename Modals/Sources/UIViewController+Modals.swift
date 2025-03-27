import UIKit
import ViewEnvironmentUI

// The Obj-C Associated Object API requires this to be mutable.
private var storedPresenterKey: UInt8 = 0
private var storedModalListObserverKey: UInt8 = 0

extension UIViewController {

    private var storedPresenter: TrampolineModalPresenter? {
        get {
            objc_getAssociatedObject(self, &storedPresenterKey) as? TrampolineModalPresenter
        }
        set {
            objc_setAssociatedObject(self, &storedPresenterKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    /// Gets a `ModalPresenter` to present modals from this view controller.
    ///
    /// The `ModalPresenter` for each view controller is lazily created. Avoid calling this property
    /// if you are not presenting a modal.
    public final var modalPresenter: ModalPresenter { presenter }

    /// Gets a `ToastPresenter` to present toasts from this view controller.
    ///
    /// The `ToastPresenter` for each view controller is lazily created. Avoid calling this property if you are not
    /// presenting a toast.
    public final var toastPresenter: ToastPresenter { presenter }

    private var presenter: ModalPresenter & ToastPresenter {
        if let presenter = storedPresenter {
            return presenter
        }

        let presenter = TrampolineModalPresenter(owner: self)
        storedPresenter = presenter

        return presenter
    }
}

extension UIViewController {

    /// Gets a `ModalListObserver` to observe a list of modals and/or toasts as it changes over time.
    ///
    /// The `ModalListObserver` for each view controller is lazily created. Avoid calling this property if you are not
    /// observing a list of modals and/or toasts.
    ///
    /// - Tag: UIViewController.modalListObserver
    ///
    public final var modalListObserver: ModalListObserver { observer }

    private var storedModalListObserver: TrampolineModalListObserver? {
        get {
            objc_getAssociatedObject(self, &storedModalListObserverKey) as? TrampolineModalListObserver
        }
        set {
            objc_setAssociatedObject(self, &storedModalListObserverKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    private var observer: ModalListObserver {
        if let observer = storedModalListObserver {
            return observer
        }

        let observer = TrampolineModalListObserver(owner: self)
        storedModalListObserver = observer

        return observer
    }
}

extension UIViewController {

    /// The nearest modal host in the view controller hierarchy.
    public var modalHost: ModalHost? {
        self as? ModalHost ?? parent?.modalHost
    }

    /// The root-most modal host in the view controller hierarchy.
    public var rootModalHost: ModalHost? {
        sequence(first: self, next: \.parent)
            .compactMap { $0 as? ModalHost }
            .last
    }

    /// Aggregate child modals by performing a depth-first traversal of the view controller hierarchy.
    @objc(mdl_aggregateChildModals)
    public func aggregateChildModals() -> ModalList {
        var modals: [PresentableModal] = []
        var toasts: [PresentableToast] = []
        var toastSafeAreaAnchors: [ToastSafeAreaAnchor] = []

        for child in children {
            let aggregateModals = child.aggregateModals()
            modals += aggregateModals.modals
            toasts += aggregateModals.toasts
            toastSafeAreaAnchors += aggregateModals.toastSafeAreaAnchors
        }

        return ModalList(
            modals: modals,
            toasts: toasts,
            toastSafeAreaAnchors: toastSafeAreaAnchors
        )
    }

    /// Aggregate child presenter by performing a depth-first traversal of the presenter's view controller hierarchy.
    @objc(mdl_aggregatePresenterModals)
    public func aggregatePresenterModals() -> ModalList {
        guard let presenter = storedPresenter else {
            // The stored presenter is created lazily when a modal is presented from a view
            // controller, so we can skip this if it hasn't been created.
            return .init()
        }

        let environment = environment

        let modalsAndAggregates = presenter
            .presentedModals(for: environment)
            .map { modal in
                (modal, modal.viewController.aggregateModals())
            }

        let modals = modalsAndAggregates.flatMap { [$0] + $1.modals }

        let toasts = presenter.presentedToasts(for: environment)
            + modalsAndAggregates.flatMap { $1.toasts }

        return ModalList(
            modals: modals,
            toasts: toasts
        )
    }

    /// Gets the `modalListObserver`'s aggregate modals.
    @objc(mdl_aggregateModalListObserverModals)
    public func aggregateModalListObserverModals() -> ModalList {
        guard let observer = storedModalListObserver else {
            // The stored presenter is created lazily when a modal is presented from a view
            // controller, so we can skip this if it hasn't been created.
            return .init()
        }

        return observer.aggregateModalList()
    }

    /// Returns the presented modals associated with this view controller and its descendants.
    ///
    /// The modal presentation system aggregates presented modals by calling this method. The
    /// default implementation retrieves this value from each of its child view controllers, and
    /// then appends any modals presented from this view controller's `ModalPresenter`, performing a
    /// depth-first traversal of the view controller hierarchy.
    ///
    /// You can override this method to change which modals are propagated up this hierarchy. For
    /// example, you can prevent some modals from being aggregated to the root depending on whether
    /// this view controller is currently visible. When overriding this method, you may find `aggregateChildModals`,
    /// `aggregatePresenterModals`, and `aggregateModalListAggregationModals` useful.
    ///
    /// - Tag: UIViewController.aggregateModals
    ///
    @objc(mdl_aggregateModals)
    open func aggregateModals() -> ModalList {
        var aggregated = aggregateChildModals() + aggregateModalListObserverModals() + aggregatePresenterModals()

        if let anchor = storedToastSafeAreaAnchor {
            // If the toast safe area has been previously accessed, `storedToastSafeAreaAnchor` will be non-nil.
            // In this case, forward it.
            aggregated = aggregated.appending(toastSafeAreaAnchors: [anchor])
        }

        return aggregated
    }
}
