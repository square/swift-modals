import UIKit

/// This is a convenience for view controllers or screens to specify their own modal styles. Types
/// do not need to conform to this protocol to be presented as modals, but this allows types to
/// provide a standard `ModalPresentationStyleProvider` to be presented with.
///
/// If your view controller or workflow screen has a standard modal presentation style (for example,
/// a dialog view controller), it can conform to this protocol and return that style from the
/// `presentationStyle` property so consumers don't have to specify a style. In UIKit,
/// `ModalPresenter` has a `present` method for view controllers that conform to this protocol.
/// In Workflows, `Modal` has an initializer that takes in screens conforming to this protocol.
///
public protocol ModalPresentable {

    var presentationStyle: ModalPresentationStyleProvider { get }

    var info: ModalInfo { get }
}

extension ModalPresentable {
    public var info: ModalInfo { .empty() }
}
