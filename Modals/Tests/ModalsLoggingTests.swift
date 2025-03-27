import XCTest
@testable import Modals

class ModalsLoggingTests: XCTestCase {

    func test_default_label() {
        XCTAssertEqual(ModalsLogging.defaultLoggerLabel, "com.squareup.modals")

        let defaultLogger = ModalsLogging.logger
        XCTAssertEqual(defaultLogger.label, "com.squareup.modals")
    }
}
