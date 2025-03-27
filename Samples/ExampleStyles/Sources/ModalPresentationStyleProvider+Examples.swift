import Modals
import UIKit
import ViewEnvironment

extension ModalPresentationStyleProvider {
    public static let full = ModalPresentationStyleProvider { viewEnvironment in
        FullModalStyle(stylesheet: viewEnvironment.modalStylesheet)
    }

    public static let card = ModalPresentationStyleProvider { viewEnvironment in
        CardModalStyle(stylesheet: viewEnvironment.modalStylesheet)
    }

    public static func sheet(onDismiss: @escaping () -> Void) -> ModalPresentationStyleProvider {
        ModalPresentationStyleProvider { viewEnvironment in
            SheetModalStyle(
                stylesheet: viewEnvironment.modalStylesheet,
                onDismiss: onDismiss
            )
        }
    }

    public static func popover(
        anchor: UICoordinateSpace,
        onDismiss: @escaping () -> Void
    ) -> ModalPresentationStyleProvider {
        ModalPresentationStyleProvider { viewEnvironment in
            PopoverModalStyle(
                stylesheet: viewEnvironment.modalStylesheet,
                anchor: anchor,
                onDismiss: onDismiss
            )
        }
    }
}
