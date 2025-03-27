import Combine
import Modals
import ViewEnvironment
import ViewEnvironmentUI
import XCTest

class AggregationTests: XCTestCase {
    func test_aggregationOrder() {
        let root = TestViewController(
            key: "root",
            presenting: [
                TestViewController(
                    key: "presented-1",
                    presenting: [
                        TestViewController(key: "presented-1"),
                        TestViewController(key: "presented-2"),
                    ],
                    containing: [
                        TestViewController(key: "contained-1"),
                        TestViewController(key: "contained-2"),
                    ],
                    modalListProviders: [
                        TestModalListProvider(
                            key: "provider-1",
                            modals: [
                                TestViewController(key: "modal-1"),
                                TestViewController(key: "modal-2"),
                            ]
                        ),
                        TestModalListProvider(
                            key: "provider-2",
                            modals: [
                                TestViewController(key: "modal-1"),
                                TestViewController(key: "modal-2"),
                            ]
                        ),
                    ]
                ),
                TestViewController(
                    key: "presented-2",
                    presenting: [
                        TestViewController(key: "presented-1"),
                        TestViewController(key: "presented-2"),
                    ],
                    containing: [
                        TestViewController(key: "contained-1"),
                        TestViewController(key: "contained-2"),
                    ]
                ),
            ],
            containing: [
                TestViewController(
                    key: "contained-1",
                    presenting: [
                        TestViewController(key: "presented-1"),
                        TestViewController(key: "presented-2"),
                    ],
                    containing: [
                        TestViewController(key: "contained-1"),
                        TestViewController(key: "contained-2"),
                    ]
                ),
                TestViewController(
                    key: "contained-2",
                    presenting: [
                        TestViewController(key: "presented-1"),
                        TestViewController(key: "presented-2"),
                    ],
                    containing: [
                        TestViewController(key: "contained-1"),
                        TestViewController(key: "contained-2"),
                    ],
                    modalListProviders: [
                        TestModalListProvider(
                            key: "provider-1",
                            modals: [
                                TestViewController(key: "modal-1"),
                                TestViewController(key: "modal-2"),
                            ]
                        ),
                        TestModalListProvider(
                            key: "provider-2",
                            modals: [
                                TestViewController(key: "modal-1"),
                                TestViewController(key: "modal-2"),
                            ]
                        ),
                    ]
                ),
            ],
            modalListProviders: [
                TestModalListProvider(
                    key: "provider-1",
                    modals: [
                        TestViewController(key: "modal-1"),
                        TestViewController(key: "modal-2"),
                    ]
                ),
                TestModalListProvider(
                    key: "provider-2",
                    modals: [
                        TestViewController(key: "modal-1"),
                        TestViewController(key: "modal-2"),
                    ]
                ),
            ]
        )
        let host = TestHost(hosting: root)
        host.setup()

        let modalList = root.aggregateModals()

        let presentationStyleIdentifiers = modalList.modals.compactMap {
            ($0.presentationStyle as! TestFullScreenStyle).identifier
        }

        XCTAssertEqual(
            presentationStyleIdentifiers,
            [
                // Presented by child view controllers
                "host.root.contained-1.presented-1",
                "host.root.contained-1.presented-2",
                "host.root.contained-2.provider-1.modal-1",
                "host.root.contained-2.provider-1.modal-2",
                "host.root.contained-2.provider-2.modal-1",
                "host.root.contained-2.provider-2.modal-2",
                "host.root.contained-2.presented-1",
                "host.root.contained-2.presented-2",

                // Providers
                "host.root.provider-1.modal-1",
                "host.root.provider-1.modal-2",
                "host.root.provider-2.modal-1",
                "host.root.provider-2.modal-2",

                // Presented by host.root, and nested modals
                "host.root.presented-1",
                "host.root.presented-1.provider-1.modal-1",
                "host.root.presented-1.provider-1.modal-2",
                "host.root.presented-1.provider-2.modal-1",
                "host.root.presented-1.provider-2.modal-2",
                "host.root.presented-1.presented-1",
                "host.root.presented-1.presented-2",
                "host.root.presented-2",
                "host.root.presented-2.presented-1",
                "host.root.presented-2.presented-2",
            ]
        )
    }

    func test_modalListAggregation() {
        let provider = TestModalListProvider(
            key: "provider",
            modals: [
                TestViewController(key: "modal-1"),
                TestViewController(key: "modal-2"),
                TestViewController(key: "modal-3"),
            ]
        )

        let root = TestViewController(
            key: "root",
            modalListProviders: [provider]
        )
        let host = TestHost(hosting: root)
        host.setup()

        /// The observation of a provider triggers a setNeedsModalUpdate
        XCTAssertEqual(host.setNeedsModalUpdateCallCount, 1)

        func identifiers(in modalList: ModalList) -> [String] {
            modalList.modals.compactMap {
                ($0.presentationStyle as! TestFullScreenStyle).identifier
            }
        }

        XCTAssertEqual(
            identifiers(in: root.aggregateModals()),
            [
                "host.root.provider.modal-1",
                "host.root.provider.modal-2",
                "host.root.provider.modal-3",
            ]
        )
        XCTAssertEqual(host.setNeedsModalUpdateCallCount, 1)

        provider.modals = [
            TestViewController(key: "modal-2"),
            TestViewController(key: "modal-4"),
        ]
        XCTAssertEqual(host.setNeedsModalUpdateCallCount, 2)

        XCTAssertEqual(
            identifiers(in: root.aggregateModals()),
            [
                "host.root.provider.modal-2",
                "host.root.provider.modal-4",
            ]
        )

        root.key = "updated-root"
        XCTAssertEqual(host.setNeedsModalUpdateCallCount, 3)

        XCTAssertEqual(
            identifiers(in: root.aggregateModals()),
            [
                "host.updated-root.provider.modal-2",
                "host.updated-root.provider.modal-4",
            ]
        )
    }

    func test_modalHost() {
        class ContainerViewConttoller: UIViewController {

            init(child: UIViewController?) {
                super.init(nibName: nil, bundle: nil)

                if let child {
                    addChild(child)
                    child.didMove(toParent: self)
                }
            }

            required init?(coder: NSCoder) { fatalError() }
        }

        let child = UIViewController()

        let middleHost = ModalHostContainerViewController(
            content: ContainerViewConttoller(
                child: child
            )
        )

        let rootmostHost = ModalHostContainerViewController(
            content: ContainerViewConttoller(
                child: middleHost
            )
        )

        let rootController = ContainerViewConttoller(child: rootmostHost)

        XCTAssertEqual(child.modalHost as? UIViewController, middleHost)
        XCTAssertEqual(child.rootModalHost as? UIViewController, rootmostHost)

        withExtendedLifetime(rootController) {}
    }
}

private class TestViewController: UIViewController, ViewEnvironmentObserving {
    var key: String {
        didSet { setNeedsEnvironmentUpdate() }
    }

    let modalViewControllers: [TestViewController]
    let containedViewControllers: [TestViewController]
    let modalListProviders: [TestModalListProvider]
    private var modalListObservations: [ModalListObservationLifetime] = []

    private var lifetimes: [ModalLifetime] = []

    init(
        key: String,
        presenting modalViewControllers: [TestViewController] = [],
        containing containedViewControllers: [TestViewController] = [],
        modalListProviders: [TestModalListProvider] = []
    ) {
        self.key = key
        self.modalViewControllers = modalViewControllers
        self.containedViewControllers = containedViewControllers
        self.modalListProviders = modalListProviders

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        for containedViewController in containedViewControllers {
            addChild(containedViewController)
            view.addSubview(containedViewController.view)
            containedViewController.didMove(toParent: self)

            containedViewController.setup()
        }

        modalListObservations = modalListProviders.map { self.modalListObserver.observe($0) }

        lifetimes = modalViewControllers.map { modalViewController in
            let lifetime = modalPresenter.present(
                modalViewController,
                style: .init { TestFullScreenStyle(identifier: $0.testKey + "." + modalViewController.key) }
            )
            modalViewController.setup()
            return lifetime
        }
    }

    func customize(environment: inout ViewEnvironment) {
        if environment.testKey.isEmpty {
            environment.testKey = key
        } else {
            environment.testKey += "." + key
        }
    }
}

private final class TestHost: TestViewController, ModalHost {
    private var presented: [UIViewController] = []
    var setNeedsModalUpdateCallCount = 0

    init(hosting root: TestViewController) {
        super.init(key: "host", containing: [root])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setNeedsModalUpdate() {
        setNeedsModalUpdateCallCount += 1
        // Stub implementation, sets up VC parent of modals to avoid assertions
        let modalVCs = aggregateModals().modals.map(\.viewController)
        for modalVC in modalVCs {
            if !presented.contains(where: { $0 === modalVC }) {
                presented.append(modalVC)

                addChild(modalVC)
                view.addSubview(modalVC.view)
                modalVC.didMove(toParent: self)
            }
        }
    }
}


private final class TestModalListProvider: ModalListProvider {

    let key: String

    private var _modalListDidChange: PassthroughSubject<Void, Never> = .init()

    var modals: [TestViewController] {
        didSet { update() }
    }

    private var presentableModals: [PresentableModal] = []

    private var environment: ViewEnvironment? {
        didSet { update() }
    }

    init(
        key: String,
        modals: [TestViewController] = []
    ) {
        self.key = key
        self.modals = modals
    }

    func update(environment: ViewEnvironment) {
        var environment = environment
        environment.testKey += "." + key
        self.environment = environment
    }

    func update() {
        defer { _modalListDidChange.send(()) }

        guard let environment else { return }

        presentableModals = modals.map {
            .init(
                viewController: $0,
                presentationStyle: TestFullScreenStyle(identifier: environment.testKey + "." + $0.key),
                info: .empty(),
                onDidPresent: nil
            )
        }
    }

    func aggregateModalList() -> ModalList { .init(modals: presentableModals) }

    var modalListDidChange: AnyPublisher<Void, Never> { _modalListDidChange.eraseToAnyPublisher() }
}


extension ViewEnvironment {
    fileprivate var testKey: String {
        get { self[TestKeyEnvironmentKey.self] }
        set { self[TestKeyEnvironmentKey.self] = newValue }
    }

    private struct TestKeyEnvironmentKey: ViewEnvironmentKey {
        static let defaultValue: String = ""
    }
}
