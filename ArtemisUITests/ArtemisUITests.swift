//
//  ArtemisUITests.swift
//  ArtemisUITests
//
//  Created by Anian Schleyer on 02.06.24.
//  Copyright © 2024 orgName. All rights reserved.
//

import XCTest

final class ArtemisUITests: XCTestCase {
    var app: XCUIApplication!

    @MainActor
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-dependency-factory-test-value"]
    }
    
    @MainActor
    func testTakeScreenshots() {
        app.launch()

        snapshot("01Dashboard")
        
        // Navigate to course details
        app.staticTexts["Interactive Learning"].tap()
        
        snapshot("02CourseView")
        
        // Navigate to messages tab
        app.tabBars.firstMatch.buttons["Messages"].tap()
        
        // Accept code of conduct
        let accept = app.buttons["Accept"]
        if accept.exists {
            accept.tap()
        }
        
        snapshot("03MessagesView")
    }
}
