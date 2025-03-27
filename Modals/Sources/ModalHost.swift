import Foundation

/// This protocol indicates that a view controller acts as the host for modal presentation.
///
/// Descendent view controllers that present modals will call `setNeedsModalUpdate` when their list
/// of presented view controllers has changed. The host should then call the `modals` property to
/// traverse the view hierarchy for an updated list of modals to present.
///
/// ## See Also:
/// - [aggregateModals](x-source-tag://UIViewController.aggregateModals)
///
/// - Tag: ModalHost
///
@objc(MDLModalHost)
public protocol ModalHost {
    /// Notifies this host that the presented modals of its descendent view controllers have
    /// changed, and should be updated. The update may not happen synchronously.
    @objc func setNeedsModalUpdate()
}
