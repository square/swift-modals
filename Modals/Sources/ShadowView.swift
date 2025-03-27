import UIKit


final class ShadowView: UIView {
    let clippingView: ClippingView

    init(content: UIView) {
        clippingView = ClippingView(content: content)

        super.init(frame: .zero)

        addSubview(clippingView)
        clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        clippingView.frame = bounds
    }

    func apply(shadow: ModalShadow, corners: ModalRoundedCorners) {
        let shadowPath = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: .init(cornerMask: corners.corners),
            cornerRadii: .init(width: corners.radius, height: corners.radius)
        ).cgPath

        layer.shadowRadius = shadow.radius
        layer.shadowOpacity = Float(shadow.opacity)
        layer.shadowOffset = CGSize(shadow.offset)
        layer.shadowColor = shadow.color.cgColor
        layer.shadowPath = shadowPath
    }

    /// This method is overridden to provide an action (e.g., animation) for the `CALayer.shadowPath` event;
    /// this ensure the shadow implicitly animates alongside changes in the views size.
    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        let keyPath = #keyPath(CALayer.shadowPath)

        guard event == keyPath,
              let currentPath = layer.shadowPath,
              let sizeAnimation = layer.animation(forKey: "bounds.size") as? CABasicAnimation
        else {
            return super.action(for: layer, forKey: event)
        }

        let animation = sizeAnimation.copy() as! CABasicAnimation
        animation.keyPath = keyPath
        animation.fromValue = currentPath
        return animation
    }
}
