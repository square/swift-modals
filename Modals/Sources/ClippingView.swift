import UIKit


final class ClippingView: UIView {
    let content: UIView

    init(content: UIView) {
        self.content = content

        super.init(frame: .zero)

        addSubview(content)
        clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        content.frame = bounds
    }
}
