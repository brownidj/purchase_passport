//
//  Purchase_PassportUITests.swift
//  Purchase PassportUITests
//
//  Created by David Browning on 1/8/2026.
//

import XCTest

final class Purchase_PassportUITests: XCTestCase {
    private var app: XCUIApplication!

    private func attachDebugArtifacts(_ name: String) {
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "\(name)-ui-tree"
        tree.lifetime = .keepAlways
        add(tree)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "\(name)-screenshot"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func debugState(_ label: String) {
        print("[UITEST] \(label)")
        print("[UITEST] app.state=\(app.state.rawValue)")
        print("[UITEST] app.windows.count=\(app.windows.count)")
    }

    private func ensureWindowExists(timeout: TimeInterval = 10) -> Bool {
        if app.windows.firstMatch.waitForExistence(timeout: timeout) {
            return true
        }

        // Recovery for macOS state-restore cases where app launches foreground with no window.
        app.typeKey("n", modifierFlags: .command)
        return app.windows.firstMatch.waitForExistence(timeout: 5)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ApplePersistenceIgnoreState", "YES"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testCanLaunchAndPresentWindow() throws {
        app.launch()
        debugState("after launch")

        let isForeground = app.wait(for: .runningForeground, timeout: 10)
        if !isForeground {
            attachDebugArtifacts("not-foreground")
        }
        XCTAssertTrue(isForeground, "App failed to reach runningForeground state")

        let hasWindow = ensureWindowExists()
        if !hasWindow {
            debugState("no-window")
            attachDebugArtifacts("no-window")
        }
        XCTAssertTrue(hasWindow, "App did not present a window")

        let sidebar = app.outlines.firstMatch
        let sidebarExists = sidebar.waitForExistence(timeout: 5)
        if !sidebarExists {
            debugState("sidebar missing")
            attachDebugArtifacts("sidebar-missing")
        }
        XCTAssertTrue(sidebarExists, "App window appeared, but the main navigation sidebar was not found")
    }

}
