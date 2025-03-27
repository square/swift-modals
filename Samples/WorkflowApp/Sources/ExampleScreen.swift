import ExampleStyles
import UIKit
import Workflow
import WorkflowModals
import WorkflowUI

struct ExampleScreen: Screen {
    var onPresent: (ExampleStyle, UICoordinateSpace) -> Void
    var onDismiss: (() -> Void)?

    func viewControllerDescription(environment: ViewEnvironment) -> ViewControllerDescription {
        ViewController.description(for: self, environment: environment)
    }
}

extension ExampleScreen {
    final class ViewController: ScreenViewController<ExampleScreen> {

        @MainActor required init(screen: ExampleScreen, environment: ViewEnvironment) {
            super.init(screen: screen, environment: environment)
        }

        private var onDismiss: (() -> Void)? = nil
        private var onPresent: (ExampleStyle, UICoordinateSpace) -> Void = { _, _ in }

        private let stackView = UIStackView()

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .systemBackground

            let buttons = ExampleStyle.allCases.map { exampleStyle in
                let button = UIButton(type: .system)
                button.setTitle("Present \(exampleStyle)", for: .normal)
                let action = UIAction(title: "Present \(exampleStyle)") { [weak self] action in
                    self?.onPresent(exampleStyle, button)
                }
                button.addAction(action, for: .touchUpInside)
                return button
            }

            for button in buttons {
                stackView.addArrangedSubview(button)
            }

            stackView.addArrangedSubview(
                UIButton(
                    type: .system,
                    primaryAction: UIAction(title: "Dismiss") { [weak self] _ in
                        self?.onDismiss?()
                    }
                )
            )

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

        override func screenDidChange(from previousScreen: ExampleScreen, previousEnvironment: ViewEnvironment) {
            super.screenDidChange(from: previousScreen, previousEnvironment: previousEnvironment)

            onPresent = screen.onPresent
            onDismiss = screen.onDismiss

            let shouldShowDismissButton = onDismiss != nil
            stackView.arrangedSubviews.last?.isHidden = !shouldShowDismissButton
        }
    }
}
