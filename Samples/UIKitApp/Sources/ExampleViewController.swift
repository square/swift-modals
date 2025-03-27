import ExampleStyles
import Modals
import UIKit

final class ExampleViewController: UIViewController {

    var onDismissTapped: (() -> Void)?

    private let stackView = UIStackView()

    // Lifetime of the modal presented by this view controller. Must be retained to keep the modal presented. Deallocating the lifetime or calling `dismiss` on it will dismiss the modal.
    private var modalLifetime: ModalLifetime?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let buttons = ExampleStyle.allCases.map { exampleStyle in
            let button = UIButton(type: .system)
            button.setTitle("Present \(exampleStyle)", for: .normal)
            let action = UIAction(title: "Present \(exampleStyle)") { [weak self] action in
                self?.presentTapped(button: button, exampleStyle: exampleStyle)
            }
            button.addAction(action, for: .touchUpInside)
            return button
        }

        for button in buttons {
            stackView.addArrangedSubview(button)
        }

        if onDismissTapped != nil {
            stackView.addArrangedSubview(
                UIButton(
                    type: .system,
                    primaryAction: UIAction(title: "Dismiss") { [weak self] _ in
                        self?.dismissTapped()
                    }
                )
            )
        }

        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center

        view.addSubview(stackView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let size = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        stackView.frame = CGRect(
            x: 0,
            y: (view.bounds.height - size.height) / 2,
            width: view.bounds.width,
            height: size.height
        )

        if size != preferredContentSize {
            preferredContentSize = size
        }
    }

    func presentTapped(button: UIButton, exampleStyle: ExampleStyle) {
        // Present a new instance of the same view controller type.
        // This demonstrates how you can recursively present modals from modals.
        let viewControllerToPresent = ExampleViewController()

        // This hook is used to dismiss the modal we're about to present. We'll pass it to the
        // view controller itself (for a dismiss button), and to styles that support an intrinsic
        // dismissal method like swiping a sheet or tapping on the scrim of a popover.
        let onDismiss: (() -> Void) = { [weak self] in
            // Releasing the lifetime will dismiss the modal. You can also call `dismiss` on it.
            self?.modalLifetime = nil
        }
        viewControllerToPresent.onDismissTapped = onDismiss

        let style: ModalPresentationStyleProvider = switch exampleStyle {
        case .full:
            .full
        case .card:
            .card
        case .popover:
            .popover(anchor: button, onDismiss: onDismiss)
        case .sheet:
            .sheet(onDismiss: onDismiss)
        }

        // Present the view controller and retain its lifetime token.
        modalLifetime = modalPresenter.present(viewControllerToPresent, style: style)
    }

    func dismissTapped() {
        onDismissTapped?()
    }
}
