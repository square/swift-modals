import Foundation


enum LocalizedStrings {


    enum ModalOverlay {

        static var dismissPopupAccessibilityLabel: String {
            NSLocalizedString(
                "modal_overlay_dismiss_a11y_label",
                tableName: nil,
                bundle: .modalsResources,
                value: "Dismiss popup",
                comment: "Read by Voiceover to indicate that the action will dismiss a popup."
            )
        }

        static var dismissPopupAccessibilityHint: String {
            NSLocalizedString(
                "modal_overlay_dismiss_a11y_hint",
                tableName: nil,
                bundle: .modalsResources,
                value: "Double tap to dismiss popup window",
                comment: "Read by Voiceover to help the user learn how to dismiss a popup."
            )
        }
    }
}
