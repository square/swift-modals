import XCTest
@testable import Modals

class ScrollViewFinderTests: XCTestCase {

    func testFindsSelfIfScrollView() {
        let finder = ModalPresentationViewController.TrackedScrollViewFinder()
        let viewController = ScrollViewController()

        finder.viewController = viewController

        let expectation = XCTestExpectation(description: "Find the scroll view")

        finder.updateTrackedScrollView { old, new in
            if new == viewController.view {
                expectation.fulfill()
            }
        }

        XCTAssertEqual(finder.scrollView, viewController.view)
        wait(for: [expectation], timeout: 0.1)
    }

    func testFindsScrollViewWithMatchingBounds() {
        let finder = ModalPresentationViewController.TrackedScrollViewFinder()
        let viewController = NestedScrollViewController(matchBounds: true)
        viewController.view.layoutIfNeeded()

        finder.viewController = viewController

        let expectation = XCTestExpectation(description: "Find the scroll view")

        finder.updateTrackedScrollView { old, new in
            if new == viewController.scrollView {
                expectation.fulfill()
            }
        }

        XCTAssertEqual(finder.scrollView, viewController.scrollView)
        wait(for: [expectation], timeout: 0.1)
    }

    func testFindsScrollViewWithMatchingWidth() {
        let finder = ModalPresentationViewController.TrackedScrollViewFinder()
        let viewController = NestedScrollViewController(matchBounds: true)
        viewController.view.layoutIfNeeded()

        viewController.scrollView.frame.origin.y += 20
        viewController.scrollView.frame.size.height -= 20

        finder.viewController = viewController

        let expectation = XCTestExpectation(description: "Find the scroll view")

        finder.updateTrackedScrollView { old, new in
            print(viewController.scrollView.frame)
            if new == viewController.scrollView {
                expectation.fulfill()
            }
        }

        XCTAssertEqual(finder.scrollView, viewController.scrollView)
        wait(for: [expectation], timeout: 0.1)
    }

    func testDoesNotFindsScrollViewWithNonMatchingBounds() {
        let finder = ModalPresentationViewController.TrackedScrollViewFinder()
        let viewController = NestedScrollViewController(matchBounds: false)

        finder.viewController = viewController

        let expectation = XCTestExpectation(description: "Don't call update")
        expectation.isInverted = true

        finder.updateTrackedScrollView { old, new in
            expectation.fulfill()
        }

        XCTAssertEqual(finder.scrollView, nil)
        wait(for: [expectation], timeout: 0.1)
    }

    func testPreviousScrollViewIsProvided() {
        let finder = ModalPresentationViewController.TrackedScrollViewFinder()
        let firstViewController = ScrollViewController()
        let secondViewController = ScrollViewController()

        finder.viewController = firstViewController

        finder.updateTrackedScrollView()

        let expectation = XCTestExpectation(
            description: "The old and new scroll view were passed in"
        )

        finder.viewController = secondViewController

        finder.updateTrackedScrollView { old, new in
            if old == firstViewController.view, new == secondViewController.view {
                expectation.fulfill()
            }
        }

        XCTAssertEqual(finder.scrollView, secondViewController.view)
        wait(for: [expectation], timeout: 0.1)
    }

    func testRemovingScrollView() {
        let finder = ModalPresentationViewController.TrackedScrollViewFinder()
        let viewController = NestedScrollViewController(matchBounds: true)

        finder.viewController = viewController

        finder.updateTrackedScrollView()

        let expectation = XCTestExpectation(
            description: "The new scroll view is nil"
        )

        viewController.scrollView.removeFromSuperview()

        finder.updateTrackedScrollView { old, new in
            if new == nil {
                expectation.fulfill()
            }
        }

        XCTAssertEqual(finder.scrollView, nil)
        wait(for: [expectation], timeout: 0.1)
    }
}

private class ScrollViewController: UIViewController {
    override func loadView() {
        view = UIScrollView()
        view.frame = UIScreen.main.bounds
    }
}

private class NestedScrollViewController: UIViewController {

    let scrollView = UIScrollView()
    let matchBounds: Bool

    init(matchBounds: Bool) {
        self.matchBounds = matchBounds
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.frame = UIScreen.main.bounds
        view.addSubview(scrollView)

        view.layoutIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if matchBounds {
            scrollView.frame = view.bounds
        } else {
            scrollView.frame = view.bounds.offsetBy(dx: 10, dy: 10)
        }
    }
}
