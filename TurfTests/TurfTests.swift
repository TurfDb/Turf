//
//  TurfTests.swift
//  TurfTests
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import XCTest
@testable import Turf

class TurfTests: XCTestCase {
    
    override func setUp() {
        super.setUp()

        let db = try! Database(name: "test")!
        let connection = db.newConnection()!
        connection.readWriteTransaction { (transaction) -> Void in
            let col = ReadOnlyCollection<Int>(name: "test", readTransaction: transaction)
            let key = col.allKeys()[0]
//            let val = col.valueForKey(12)
        }

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
