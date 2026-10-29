import XCTest

/// 5タブのスクリーンショットを撮る（App Store 提出用）。ci.yml の workflow_dispatch（screenshots=true）で実行。
final class ScreenshotTests: XCTestCase {
    @MainActor
    func testCaptureAllTabs() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-notice.accepted.v1", "YES"]
        app.launch()
        let tabs = ["home", "spots", "catch", "zukan", "tackle"]
        for tab in tabs {
            if tab != "home" {
                let button = app.buttons["tab.\(tab)"]
                if button.waitForExistence(timeout: 5) { button.tap() }
            }
            sleep(2)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "\(tabs.firstIndex(of: tab).map { $0 + 1 } ?? 0)-\(tab)"
            attachment.lifetime = .keepAlways
            add(attachment)
            if tab == "catch" {
                // Catch にはタブバーが無いので閉じるで戻る
                let close = app.buttons["catch.close"]
                if close.waitForExistence(timeout: 3) { close.tap() }
            }
        }
    }
}
