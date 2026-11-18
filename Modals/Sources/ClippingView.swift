import UIKit


final class ClippingView: UIView {
    let content: UIView

    /// Insets the content from the bounds. See `ModalDisplayValues.contentInsets`.
    var contentInsets: UIEdgeInsets = .zero {
        didSet {
            if contentInsets != oldValue {
                setNeedsLayout()
            }
        }
    }

    /// Fills the area between the bounds and the inset content. See `ModalDisplayValues.contentInsetsFillColor`.
    var contentInsetsFillColor: UIColor? {
        didSet {
            guard contentInsetsFillColor != oldValue else { return }

            if contentInsetsFillColor != nil, fillView == nil {
                let fillView = InsetFillView()
                // Above the content, so the fill also covers anything the content draws outside its frame.
                addSubview(fillView)
                self.fillView = fillView
            }

            fillView?.fillColor = contentInsetsFillColor
            setNeedsLayout()
        }
    }

    /// Created the first time a fill color is set, so modals without a fill keep their view hierarchy.
    private var fillView: InsetFillView?

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
        content.frame = bounds.inset(by: contentInsets)
        fillView?.frame = bounds
        fillView?.viewport = content.frame
    }
}

/// Fills its bounds with a color, except for a viewport through which the content beneath it shows. It never
/// receives touches.
final class InsetFillView: UIView {
    var fillColor: UIColor? {
        didSet {
            if fillColor != oldValue {
                setNeedsLayout()
            }
        }
    }

    /// The area left unfilled, so the content beneath shows through it, in this view's coordinate space.
    var viewport: CGRect = .zero {
        didSet {
            if viewport != oldValue {
                setNeedsLayout()
            }
        }
    }

    /// One strip per edge, which together cover everything outside `viewport`.
    private let occlusionStrips = (0..<4).map { _ in UIView() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        for occlusionStrip in occlusionStrips {
            occlusionStrip.isUserInteractionEnabled = false
            addSubview(occlusionStrip)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()

        for (occlusionStrip, frame) in zip(occlusionStrips, Self.occlusionStripFrames(in: bounds, around: viewport)) {
            occlusionStrip.frame = frame
            occlusionStrip.backgroundColor = fillColor
        }
    }

    /// Keeps one strip per edge so an animated inset change cannot move a strip across the content.
    static func occlusionStripFrames(in bounds: CGRect, around viewport: CGRect) -> [CGRect] {
        let viewport = viewport.intersection(bounds)

        guard !viewport.isNull else {
            return [bounds, .zero, .zero, .zero]
        }

        return [
            CGRect(x: bounds.minX, y: bounds.minY, width: viewport.minX - bounds.minX, height: bounds.height),
            CGRect(x: viewport.maxX, y: bounds.minY, width: bounds.maxX - viewport.maxX, height: bounds.height),
            CGRect(x: viewport.minX, y: bounds.minY, width: viewport.width, height: viewport.minY - bounds.minY),
            CGRect(x: viewport.minX, y: viewport.maxY, width: viewport.width, height: bounds.maxY - viewport.maxY),
        ]
    }
}

extension ClippingView {
    func apply(contentInsetsOf displayValues: ModalDisplayValues) {
        contentInsets = displayValues.contentInsets
        contentInsetsFillColor = displayValues.contentInsetsFillColor
    }
}
