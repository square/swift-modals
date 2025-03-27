import UIKit


// Modals block the accessibility/ interactivity of all views behind the presentation.
// In some instances we use a modal presentation to present a view alongside a specific UI element which needs to remain interactive.
// This class provides an (invisible) "proxy" view that we position in the same rect as the inaccessable view but above the presentation layer the Z axis.
// By proxying the accessibility representation from the source view outside of the view hierarchy, Voiceover is able to present it's UI as though the source view were accessible.
final class AccessibilityProxyView: UIView {

    // The view that will provide the accessibility representation
    weak var source: UIView? = nil {
        didSet {
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureProxies()
    }

    internal func configureProxies() {
        guard let source else {
            subviews.forEach { $0.removeFromSuperview() }
            return
        }

        let elements = source.recursiveAccessibleSubviews()
            .compactMap { $0 as? NSObject }
            .sorted(by: { !CGRectContainsRect($1.accessibilityFrame, $0.accessibilityFrame) })

        var proxies = subviews.compactMap { $0 as? Proxy }

        for element in elements {
            let frame = UIAccessibility.convertFromScreenCoordinates(element.accessibilityFrame, in: self)
            if let index = proxies.firstIndex(where: { $0.proxiedElement == element }) {
                let update = proxies.remove(at: index)
                update.frame = frame
            } else {
                addSubview(Proxy(
                    element: element,
                    frame: frame
                ))
            }
        }

        for remaining in proxies {
            remaining.removeFromSuperview()
        }
    }
}

extension UIAccessibility {
    // Because accessibility runs outside of your app's process and has to interact with the potential of multiple apps
    // running simultaniously, it uses the UIScreen.coordinateSpace which is distinct from the coordinate space of the UIWindow.
    //
    // It's easy to convert an accessibilityFrame CGRect from view to screen coordinates using the UIAccessibility.convertToScreenCoordinates(_:in:)
    // helper method, but there isn't a corresponding method to go back to view coordinates.

    // This method converts an accessibilityFrame (in the screen coordinate space) first to the window coordinate space and then down to the view space.

    static func convertFromScreenCoordinates(_ rect: CGRect, in view: UIView) -> CGRect {
        guard let window = view.window else { return .zero }
        let windowRect = window.coordinateSpace.convert(rect, from: window.screen.coordinateSpace)
        return view.convert(windowRect, from: nil)
    }
}

extension AccessibilityProxyView {
    internal final class Proxy<T: NSObject>: UIView, AXCustomContentProvider {

        weak var proxiedElement: T?

        init(element: T?, frame: CGRect) {
            super.init(frame: frame)
            proxiedElement = element
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var isAccessibilityElement: Bool {
            get { proxiedElement?.isAccessibilityElement ?? false }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        override var accessibilityLabel: String? {
            get { proxiedElement?.accessibilityLabel }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        override var accessibilityValue: String? {
            get { proxiedElement?.accessibilityValue }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        override var accessibilityHint: String? {
            get { proxiedElement?.accessibilityHint }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        override var accessibilityTraits: UIAccessibilityTraits {
            get { proxiedElement?.accessibilityTraits ?? .none }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        override var accessibilityFrame: CGRect {
            get { proxiedElement?.accessibilityFrame ?? .zero }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        override var accessibilityActivationPoint: CGPoint {
            get { proxiedElement?.accessibilityActivationPoint ?? .zero }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        override var accessibilityPath: UIBezierPath? {
            get { proxiedElement?.accessibilityPath }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        override func accessibilityActivate() -> Bool {
            proxiedElement?.accessibilityActivate() ?? false
        }

        override func accessibilityIncrement() {
            proxiedElement?.accessibilityIncrement()
        }

        override func accessibilityDecrement() {
            proxiedElement?.accessibilityDecrement()
        }

        override var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
            get { proxiedElement?.accessibilityCustomRotors }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
            get { proxiedElement?.accessibilityCustomActions ?? super.accessibilityCustomActions }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        var accessibilityCustomContent: [AXCustomContent]! {
            get { (proxiedElement as? AXCustomContentProvider)?.accessibilityCustomContent ?? [] }
            set { fatalError("Proxy view accessibility is not settable") }
        }


        @available(iOS 17.0, *)
        override var accessibilityLabelBlock: AXStringReturnBlock? {
            get { proxiedElement?.accessibilityLabelBlock }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        @available(iOS 17.0, *)
        override var accessibilityValueBlock: AXStringReturnBlock? {
            get { proxiedElement?.accessibilityValueBlock }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        @available(iOS 17.0, *)
        override var accessibilityHintBlock: AXStringReturnBlock? {
            get { proxiedElement?.accessibilityHintBlock }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        @available(iOS 17.0, *)
        override var accessibilityTraitsBlock: AXTraitsReturnBlock? {
            get { proxiedElement?.accessibilityTraitsBlock }
            set { fatalError("Proxy view accessibility is not settable") }
        }

        @available(iOS 17.0, *)
        override var accessibilityIdentifierBlock: AXStringReturnBlock? {
            get { proxiedElement?.accessibilityIdentifierBlock }
            set { fatalError("Proxy view accessibility is not settable") }
        }
    }
}

extension AccessibilityProxyView.Proxy where T: AXCustomContentProvider {

    var accessibilityCustomContent: [AXCustomContent]! {
        get { proxiedElement?.accessibilityCustomContent ?? [] }
        set { fatalError("Proxy view accessibility is not settable") }
    }

    @available(iOS 17.0, *)
    var accessibilityCustomContentBlock: AXCustomContentReturnBlock? {
        get { proxiedElement?.accessibilityCustomContentBlock ?? { self.accessibilityCustomContent } }
        set { fatalError("Proxy view accessibility is not settable") }
    }
}

extension UIView {
    func recursiveAccessibleSubviews() -> [Any] {
        guard !isAccessibilityElement else { return [self] }
        return subviews.flatMap { subview -> [Any] in
            if subview.accessibilityElementsHidden || subview.isHidden {
                return []
            }
            if let accessibilityElements = subview.accessibilityElements {
                return accessibilityElements
            }
            if subview.isAccessibilityElement {
                return [subview]
            }
            return subview.recursiveAccessibleSubviews()
        }
    }
}
