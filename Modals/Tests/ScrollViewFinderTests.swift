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

    @MainActor
    func testUpdatesVisiblePageWithoutLayingOutHostAgain() {
        let viewController = PagingScrollViewController()
        let finder = ModalPresentationViewController.TrackedScrollViewFinder()
        finder.viewController = viewController
        finder.updateTrackedScrollView()
        XCTAssertIdentical(finder.scrollView, viewController.firstPageScrollView)
        let layoutCount = viewController.layoutCount

        viewController.pager.contentOffset.x = viewController.pager.bounds.width
        var previousScrollView: UIScrollView?
        var nextScrollView: UIScrollView?
        finder.updateTrackedScrollView { old, new in
            previousScrollView = old
            nextScrollView = new
        }

        XCTAssertEqual(viewController.layoutCount, layoutCount)
        XCTAssertIdentical(previousScrollView, viewController.firstPageScrollView)
        XCTAssertIdentical(nextScrollView, viewController.secondPageScrollView)
        XCTAssertIdentical(finder.scrollView, viewController.secondPageScrollView)
    }

    @MainActor
    func testDoesNotTrackOffscreenPageWhenVisiblePageHasNoScrollView() {
        let viewController = PagingScrollViewController(secondPageHasScrollView: false)
        viewController.loadViewIfNeeded()
        viewController.pager.contentOffset.x = viewController.pager.bounds.width
        let finder = ModalPresentationViewController.TrackedScrollViewFinder()
        finder.viewController = viewController

        finder.updateTrackedScrollView()

        XCTAssertNil(finder.scrollView)
    }

    @MainActor
    func testTracksVerticalPagerInsteadOfItsPageScrollViews() {
        let viewController = PagingScrollViewController(verticalPaging: true)
        let finder = ModalPresentationViewController.TrackedScrollViewFinder()
        finder.viewController = viewController

        finder.updateTrackedScrollView()

        XCTAssertIdentical(finder.scrollView, viewController.pager)
    }
}

@MainActor
private final class PagingScrollViewController: UIViewController {
    let pager = UIScrollView()
    let firstPageScrollView = UIScrollView()
    let secondPageScrollView = UIScrollView()
    private(set) var layoutCount = 0
    private let secondPageHasScrollView: Bool
    private let verticalPaging: Bool

    init(secondPageHasScrollView: Bool = true, verticalPaging: Bool = false) {
        self.secondPageHasScrollView = secondPageHasScrollView
        self.verticalPaging = verticalPaging
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = pager
        pager.frame = CGRect(x: 0, y: 0, width: 400, height: 600)
        pager.isPagingEnabled = true
        pager.contentInsetAdjustmentBehavior = .never
        pager.contentSize = CGSize(
            width: pager.bounds.width * (verticalPaging ? 1 : 2),
            height: pager.bounds.height * (verticalPaging ? 2 : 1)
        )

        for (index, scrollView) in [firstPageScrollView, secondPageScrollView].enumerated() {
            let page = UIView(frame: pager.bounds.offsetBy(
                dx: verticalPaging ? 0 : CGFloat(index) * pager.bounds.width,
                dy: verticalPaging ? CGFloat(index) * pager.bounds.height : 0
            ))
            pager.addSubview(page)

            let child = UIViewController()
            if index == 0 || secondPageHasScrollView {
                child.view = scrollView
                scrollView.contentInsetAdjustmentBehavior = .never
                scrollView.contentSize = CGSize(width: page.bounds.width, height: page.bounds.height * 2)
            }
            addChild(child)
            child.view.frame = page.bounds
            page.addSubview(child.view)
            child.didMove(toParent: self)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutCount += 1
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
