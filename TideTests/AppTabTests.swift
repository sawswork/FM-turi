import TideCore
import XCTest
@testable import Tide

final class AppTabTests: XCTestCase {
    func testFiveTabsInSpecOrder() {
        XCTAssertEqual(AppTab.allCases, [.home, .spots, .catchFish, .zukan, .tackle])
    }

    func testCenterTabIsCamera() {
        XCTAssertEqual(AppTab.allCases[2].icon, .camera)
    }

    func testDeepLinkCatchSelectsCatchTab() {
        XCTAssertEqual(AppTab(deepLink: .catchScreen), .catchFish)
    }
}
