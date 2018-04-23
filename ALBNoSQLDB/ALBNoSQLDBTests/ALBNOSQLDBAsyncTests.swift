//
//  ALBNOSQLDBAsyncTests.swift
//  ALBNoSQLDBTests
//
//  Created by Aaron Bratcher on 4/23/18.
//  Copyright © 2018 Aaron Bratcher. All rights reserved.
//

import XCTest
@testable import ALBNoSQLDB

class ALBNOSQLDBAsyncTests: XCTestCase {


	override func setUp() {
		super.setUp()
		let searchPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentFolderPath = searchPaths[0]
		let dbFilePath = documentFolderPath + "/TestDB.db"

		ALBNoSQLDB.setFileLocation(URL(fileURLWithPath: dbFilePath))
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testAsync() {
		let expectations = expectation(description: "AsyncExpectations")
		expectations.expectedFulfillmentCount = 4

		DispatchQueue.global(qos: .userInteractive).async {
			let tableName = "table4"
			_ = ALBNoSQLDB.dropTable(tableName)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey1", value: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey2", value: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey3", value: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey4", value: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey5", value: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

			if let keys = ALBNoSQLDB.keysInTable(tableName) {
				XCTAssert(keys.count == 5)
			} else {
				XCTAssert(false)
			}


			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey1")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey2")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey3")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey4")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey5")

			if let keys = ALBNoSQLDB.keysInTable(tableName) {
				XCTAssert(keys.count == 0)
			} else {
				XCTAssert(false)
			}

			expectations.fulfill()
		}


		DispatchQueue.global(qos: .background).async {
			let tableName = "table3"
			_ = ALBNoSQLDB.dropTable(tableName)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey1", value: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey2", value: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey3", value: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey4", value: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey5", value: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

			if let keys = ALBNoSQLDB.keysInTable(tableName) {
				XCTAssert(keys.count == 5)
			} else {
				XCTAssert(false)
			}

			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey1")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey2")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey3")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey4")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey5")

			if let keys = ALBNoSQLDB.keysInTable(tableName) {
				XCTAssert(keys.count == 0)
			} else {
				XCTAssert(false)
			}

			expectations.fulfill()
		}

		DispatchQueue.global(qos: .default).async {
			let tableName = "table2"
			_ = ALBNoSQLDB.dropTable(tableName)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey1", value: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey2", value: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey3", value: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey4", value: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey5", value: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

			if let keys = ALBNoSQLDB.keysInTable(tableName) {
				XCTAssert(keys.count == 5)
			} else {
				XCTAssert(false)
			}

			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey1")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey2")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey3")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey4")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey5")

			if let keys = ALBNoSQLDB.keysInTable(tableName) {
				XCTAssert(keys.count == 0)
			} else {
				XCTAssert(false)
			}


			expectations.fulfill()
		}

		DispatchQueue.main.async {
			let tableName = "table1"
			_ = ALBNoSQLDB.dropTable(tableName)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey1", value: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey2", value: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey3", value: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey4", value: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
			_ = ALBNoSQLDB.setValue(table: tableName, key: "testKey5", value: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

			if let keys = ALBNoSQLDB.keysInTable(tableName) {
				XCTAssert(keys.count == 5)
			} else {
				XCTAssert(false)
			}

			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey1")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey2")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey3")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey4")
			_ = ALBNoSQLDB.deleteForKey(table: tableName, key: "testKey5")

			if let keys = ALBNoSQLDB.keysInTable(tableName) {
				XCTAssert(keys.count == 0)
			} else {
				XCTAssert(false)
			}


			expectations.fulfill()
		}

		waitForExpectations(timeout: 2, handler: nil)
	}

}
