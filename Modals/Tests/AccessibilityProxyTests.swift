import UIKit
import XCTest

@testable import Modals

class AccessibilityProxyTests: XCTestCase {


    func test_view() {
        class InteractiveElement: UIView {
            init(frame: CGRect, activate: @escaping () -> Bool) {
                self.activate = activate
                super.init(frame: frame)
            }

            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }

            var activate: () -> Bool
            override func accessibilityActivate() -> Bool {
                activate()
            }
        }

        let container = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        var interactiveActivated = false
        let interactive = InteractiveElement(frame: CGRect(x: 0, y: 0, width: 50, height: 50)) {
            interactiveActivated = true
            return true
        }

        interactive.accessibilityLabel = "interactive"
        interactive.isAccessibilityElement = true
        container.addSubview(interactive)

        let element = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
        element.isAccessibilityElement = true
        element.accessibilityLabel = "element"
        container.insertSubview(element, at: 0)

        let passhtough = AccessibilityProxyView(frame: .zero)
        passhtough.source = container
        passhtough.configureProxies()

        let subviews = passhtough.subviews
        XCTAssertEqual(subviews.count, 2)

        XCTAssertEqual(subviews.first?.accessibilityLabel, "element")
        XCTAssertEqual(subviews.last?.accessibilityLabel, "interactive")

        subviews.last?.accessibilityActivate()
        XCTAssertTrue(interactiveActivated)
    }

    func test_proxy_weakReference() {
        var element: UIView? = UIView(frame: .zero)
        element?.isAccessibilityElement = true
        element?.accessibilityLabel = "label"

        let proxy = AccessibilityProxyView.Proxy(element: element, frame: .zero)

        XCTAssertEqual(proxy.accessibilityLabel, "label")
        XCTAssertTrue(proxy.isAccessibilityElement)

        element = nil

        XCTAssertFalse(proxy.isAccessibilityElement)
        XCTAssertNil(proxy.accessibilityLabel)

    }

    func test_proxy_customContent() {

        class TestItem: NSObject, AXCustomContentProvider {
            var accessibilityCustomContent: [AXCustomContent]! = [
                AXCustomContent(label: "label", value: "value"),
            ]
        }

        let item = TestItem()
        let proxy = AccessibilityProxyView.Proxy(element: item, frame: .zero)
        let content = proxy.accessibilityCustomContent
        XCTAssertEqual(content?.count, 1)
        XCTAssertEqual(content, item.accessibilityCustomContent)

        if #available(iOS 17.0, *) {
            // accessibilityCustomContentBlock is preferred by voiceover if implemented, so we should return the content even if the proxied item doesn't implement it.
            let blockContent = proxy.accessibilityCustomContentBlock?()
            XCTAssertEqual(blockContent, content)
        }
    }

    @available(iOS 17.0, *)
    func test_proxy_customContentBlock() {
        class BlockTestItem: NSObject, AXCustomContentProvider {
            var accessibilityCustomContent: [AXCustomContent]! = [
                AXCustomContent(label: "varLabel", value: "varValue"),
            ]
            var accessibilityCustomContentBlock: AXCustomContentReturnBlock? = { [
                AXCustomContent(label: "blockLabel", value: "blockValue"),
            ] }
        }

        let item = BlockTestItem()
        let proxy = AccessibilityProxyView.Proxy(element: item, frame: .zero)
        let content = proxy.accessibilityCustomContentBlock?()
        // accessibilityCustomContentBlock is preferred by voiceover if implemented, so we should return the content from the block based API if possible.
        XCTAssertEqual(content?.first?.label, "blockLabel")
        XCTAssertEqual(content?.first?.value, "blockValue")
    }
}
