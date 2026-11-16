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
        fillView?.holeFrame = content.frame
    }
}

/// Fills its bounds with a color, except for a hole. It never receives touches.
final class InsetFillView: UIView {
    var fillColor: UIColor? {
        didSet {
            if fillColor != oldValue {
                setNeedsLayout()
            }
        }
    }

    /// The unfilled area, in this view's coordinate space.
    var holeFrame: CGRect = .zero {
        didSet {
            if holeFrame != oldValue {
                setNeedsLayout()
            }
        }
    }

    private let strips = (0..<4).map { _ in UIView() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        for strip in strips {
            strip.isUserInteractionEnabled = false
            addSubview(strip)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()

        for (strip, frame) in zip(strips, Self.stripFrames(in: bounds, around: holeFrame)) {
            strip.frame = frame
            strip.backgroundColor = fillColor
        }
    }

    /// Keeps one strip per edge so an animated inset change cannot move a strip across the content.
    static func stripFrames(in bounds: CGRect, around hole: CGRect) -> [CGRect] {
        let hole = hole.intersection(bounds)

        guard !hole.isNull else {
            return [bounds, .zero, .zero, .zero]
        }

        return [
            CGRect(x: bounds.minX, y: bounds.minY, width: hole.minX - bounds.minX, height: bounds.height),
            CGRect(x: hole.maxX, y: bounds.minY, width: bounds.maxX - hole.maxX, height: bounds.height),
            CGRect(x: hole.minX, y: bounds.minY, width: hole.width, height: hole.minY - bounds.minY),
            CGRect(x: hole.minX, y: hole.maxY, width: hole.width, height: bounds.maxY - hole.maxY),
        ]

    }
}

extension ClippingView {
    func apply(contentInsetsOf displayValues: ModalDisplayValues) {
        contentInsets = displayValues.contentInsets
        contentInsetsFillColor = displayValues.contentInsetsFillColor
    }
}
