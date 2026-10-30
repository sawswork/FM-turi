import XCTest

/// 5タブのスクリーンショットを撮る（App Store 提出用）。ci.yml の workflow_dispatch（screenshots=true）で実行。
final class ScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    func testCaptureAllTabs() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-notice.accepted.v1", "YES"]
        // 位置情報などのシステムダイアログは許可して閉じる
        addUIInterruptionMonitor(withDescription: "system alert") { alert in
            for label in ["Allow While Using App", "Allow Once", "Allow", "OK", "許可"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))
        // 割り込みモニターを動かすため、何も無い場所（上部帯の中央）をタップする
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
        let tabs = ["home", "spots", "catch", "zukan", "tackle"]
        for (index, tab) in tabs.enumerated() {
            if tab != "home" {
                let button = app.buttons["tab.\(tab)"]
                if button.waitForExistence(timeout: 10) { button.tap() }
            }
            sleep(3)
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "\(index + 1)-\(tab)"
            attachment.lifetime = .keepAlways
            add(attachment)
            if tab == "catch" {
                // Catch にはタブバーが無いので閉じるで戻る
                let close = app.buttons["catch.close"]
                if close.waitForExistence(timeout: 5) { close.tap() }
            }
        }
    }
}
