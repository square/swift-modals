import Modals
import UIKit
import ViewEnvironment

public struct ModalStylesheet {
    public var overlayOpacity: CGFloat = 0.75

    public var minimumWidth: CGFloat = 200
    public var cardMaximumWidth: CGFloat = 500
    public var maximumHeight: CGFloat = 500

    public var horizontalInsets: CGFloat = 8
    public var verticalInsets: CGFloat = 8

    public var animationDuration: TimeInterval = 0.3

    /// Modals that scale in will animate from this scale to full size on the transition in.
    public var enterScale: CGFloat = 0.75
    /// Modals that scale in will animate from full size to this scale on the transition out.
    public var exitScale: CGFloat = 0.75

    public var cornerRadius: CGFloat = 6

    public var handleColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.4)
    public var handleSize = CGSize(width: 56, height: 6)
    public var handleOffset: CGFloat = 8

    public var horizontalAnchorSpacing: CGFloat = 8
    public var verticalAnchorSpacing: CGFloat = 8

    public var reverseTransitionInset: CGFloat = 32

    public var shadow: ModalShadow = ModalShadow(
        radius: 9,
        opacity: 0.2,
        offset: UIOffset(horizontal: 0, vertical: 4),
        color: .black
    )

    public var scaleInAnimation: ModalAnimation {
        .curve(.easeOut, duration: animationDuration)
    }

    public var scaleOutAnimation: ModalAnimation {
        .curve(.easeIn, duration: animationDuration)
    }

    public init() {}
}

enum ModalStylesheetKey: ViewEnvironmentKey {
    static let defaultValue = ModalStylesheet()
}

extension ViewEnvironment {
    public var modalStylesheet: ModalStylesheet {
        get { self[ModalStylesheetKey.self] }
        set { self[ModalStylesheetKey.self] = newValue }
    }
}
