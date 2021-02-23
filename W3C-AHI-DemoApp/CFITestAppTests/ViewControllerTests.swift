//
//  ViewControllerTests.swift
//  CFITestAppTests
//
//  Created by brillio on 6/24/19.
//  Copyright © 2019 mastercard. All rights reserved.
//

import XCTest
@testable import CFITestApp

class ViewControllerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUrlisValid(){
        let viewController = ViewController();
        let url = "https://www.ghomediator.com"
        XCTAssertTrue(viewController.canOpenURL(url));
        let url1 = "ghomediator.com"
        XCTAssertFalse(viewController.canOpenURL(url1));
//        XCTAssertFalse(viewController)
    }

}
