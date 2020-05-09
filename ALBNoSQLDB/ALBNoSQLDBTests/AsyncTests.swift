//
//  ALBNOSQLDBAsyncTests.swift
//  ALBNoSQLDBTests
//
//  Created by Aaron Bratcher on 4/23/18.
//  Copyright © 2018 Aaron Bratcher. All rights reserved.
//

import XCTest
@testable import ALBNoSQLDB

class AsyncTests: XCTestCase {
	lazy var db: ALBNoSQLDB = {
		return dbForTestClass(className: String(describing: type(of: self)))
	}()

	override func setUpWithError() throws {
		super.setUp()

		db.dropAllTables()
	}

	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		db.close()
		removeDB(for: String(describing: type(of: self)))
	}


	func testAsync() {
		let expectations = expectation(description: "AsyncExpectations")
		expectations.expectedFulfillmentCount = 4

		DispatchQueue.global(qos: .userInteractive).async {
			let table: DBTable = "asyncTable4"
			self.db.dropTable(table)
			self.db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":2,\"value2\":1}")
			self.db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":3,\"value2\":1}")
			self.db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":2,\"value2\":3}")
			self.db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":1,\"value2\":1}")
			self.db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":2,\"value2\":2}")

			if let keys = self.db.keysInTable(table) {
				XCTAssert(keys.count == 5)
			} else {
				XCTAssert(false)
			}


			self.db.deleteFromTable(table, for: "testKey1")
			self.db.deleteFromTable(table, for: "testKey2")
			self.db.deleteFromTable(table, for: "testKey3")
			self.db.deleteFromTable(table, for: "testKey4")
			self.db.deleteFromTable(table, for: "testKey5")

			if let keys = self.db.keysInTable(table) {
				XCTAssert(keys.count == 0)
			} else {
				XCTAssert(false)
			}

			expectations.fulfill()
		}


		DispatchQueue.global(qos: .background).async {
			let table: DBTable = "asyncTable3"
			self.db.dropTable(table)
			self.db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

			if let keys = self.db.keysInTable(table) {
				XCTAssert(keys.count == 5)
			} else {
				XCTAssert(false)
			}

			self.db.deleteFromTable(table, for: "testKey1")
			self.db.deleteFromTable(table, for: "testKey2")
			self.db.deleteFromTable(table, for: "testKey3")
			self.db.deleteFromTable(table, for: "testKey4")
			self.db.deleteFromTable(table, for: "testKey5")

			if let keys = self.db.keysInTable(table) {
				XCTAssert(keys.count == 0)
			} else {
				XCTAssert(false)
			}

			expectations.fulfill()
		}

		DispatchQueue.global(qos: .default).async {
			let table: DBTable = "asyncTable2"
			self.db.dropTable(table)
			self.db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

			if let keys = self.db.keysInTable(table) {
				XCTAssert(keys.count == 5)
			} else {
				XCTAssert(false)
			}

			self.db.deleteFromTable(table, for: "testKey1")
			self.db.deleteFromTable(table, for: "testKey2")
			self.db.deleteFromTable(table, for: "testKey3")
			self.db.deleteFromTable(table, for: "testKey4")
			self.db.deleteFromTable(table, for: "testKey5")

			if let keys = self.db.keysInTable(table) {
				XCTAssert(keys.count == 0)
			} else {
				XCTAssert(false)
			}


			expectations.fulfill()
		}

		DispatchQueue.main.async {
			let table: DBTable = "asyncTable1"
			self.db.dropTable(table)
			self.db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
			self.db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

			if let keys = self.db.keysInTable(table) {
				XCTAssert(keys.count == 5)
			} else {
				XCTAssert(false)
			}

			self.db.deleteFromTable(table, for: "testKey1")
			self.db.deleteFromTable(table, for: "testKey2")
			self.db.deleteFromTable(table, for: "testKey3")
			self.db.deleteFromTable(table, for: "testKey4")
			self.db.deleteFromTable(table, for: "testKey5")

			if let keys = self.db.keysInTable(table) {
				XCTAssert(keys.count == 0)
			} else {
				XCTAssert(false)
			}


			expectations.fulfill()
		}

		waitForExpectations(timeout: 20, handler: nil)
	}

	func testAsyncTableKeys() {
		let table: DBTable = "asyncTable2"
		db.dropTable(table)
		db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

		db.keysInTable(table) { (results) in
			if case .success(let rows) = results {
				XCTAssert(rows.count == 5)
			} else {
				XCTFail()
			}
		}
	}

	func testAsyncTableHasKey() {
		let table: DBTable = "asyncTable3"
		db.dropTable(table)
		db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

		db.tableHasKey(table: table, key: "testKey4") { (results) in
			if case .success(let hasKey) = results {
				XCTAssert(hasKey)
			} else {
				XCTFail()
			}
		}
	}

	func testAsyncValues() {
		let table: DBTable = "asyncTable4"
		db.dropTable(table)
		db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

		db.valueFromTable(table, for: "testKey3") { (results) in
			if case .success(let value) = results {
				XCTAssert(value == "{\"numValue\":2,\"value2\":3}")
			} else {
				XCTFail()
			}
		}
	}
}
