//
//  StandardTableItemTests.swift
//
//  Created by me on 11/29/18.
//  Copyright © 2018 DD/MF & Associates. All rights reserved.
//

import XCTest
import GenericTableView

class StandardTableItemTests: XCTestCase
{
    override func setUp()
    {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown()
    {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testStringInit()
    {
        let pair = ("foo", "bar")
        let item = StandardTableItem(pair.0, pair.1)
        
        XCTAssertEqual(item.title, pair.0)
        XCTAssertEqual(item.detail, pair.1)
    }

    func testDefaultInit()
    {
        let item = StandardTableItem()
        
        let expectedValues: [StandardTableItem.Property : Int] =
        [
            .editingStyle: TableItem.EditingStyle.none.rawValue,
            .accessoryType: TableItem.AccessoryType.none.rawValue,
            .selectionStyle: TableItem.SelectionStyle.default.rawValue,
        ]
        
        StandardTableItem.Property.allCases.forEach()
        {
            let key = $0.rawValue
            if item.responds(to: NSSelectorFromString(key))
            {
                let value = item.value(forKey: key)
                let expectedValue = expectedValues[$0]
                XCTAssertEqual(value as? Int, expectedValue)
            }
        }
    }
}
