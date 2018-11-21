//
//  ALBNoSQLDBTests.swift
//  ALBNoSQLDBTests
//
//  Created by Aaron Bratcher on 1/8/15.
//  Copyright (c) 2015 Aaron Bratcher. All rights reserved.
//

import Foundation
import XCTest
@testable import ALBNoSQLDB

class ALBNoSQLDBTests: XCTestCase {
	lazy var db: ALBNoSQLDB = {
		return dbForTestClass(className: String(describing: type(of: self)))
	}()
	
	override func setUp() {
		super.setUp()

		db.dropAllTables()
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
		db.close()
		let path = pathForDB(className: String(describing: type(of: self)))
		let fileExists = FileManager.default.fileExists(atPath: path)
		if fileExists {
			try? FileManager.default.removeItem(atPath: path)
		}
	}
	
	func testURLOpen() {
		let path = pathForDB(className: String(describing: type(of: self))) + "testURL"
		let location = URL(fileURLWithPath: path)
		
		let db = ALBNoSQLDB()
		
		XCTAssert(db.open(location))
		db.close()
		
		let fileExists = FileManager.default.fileExists(atPath: path)
		if fileExists {
			try? FileManager.default.removeItem(atPath: path)
		}
	}

	func testEmptyInsert() {
		let key = "emptykey"

		let table: DBTable = "table1"
		let successful = db.setValueInTable(table, for: key, to: "{}", autoDeleteAfter: nil)
		XCTAssert(successful, "setValueFailed")

		let jsonValue = db.valueFromTable(table, for: key)
		XCTAssert(jsonValue != nil, "No value returned")
	}

	func testSimpleInsert() {
		let table: DBTable = "table1"
		let key = "SIMPLEINSERTKEY"
		let sample = "{\"numValue\":1,\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"link\":true}"
		let sampleData = sample.data(using: String.Encoding.utf8, allowLossyConversion: false)!
		let sampleDict = (try? JSONSerialization.jsonObject(with: sampleData, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: AnyObject]
		let successful = db.setValueInTable(table, for: key, to: sample, autoDeleteAfter: nil)

		XCTAssert(successful, "setValueFailed")

		let jsonValue = db.valueFromTable(table, for: key)

		XCTAssert(jsonValue != nil, "No value returned")

		// compare dict values
		if let jsonValue = jsonValue {
			let dataValue = jsonValue.data(using: String.Encoding.utf8, allowLossyConversion: false)!
			let objectValues = (try? JSONSerialization.jsonObject(with: dataValue, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: AnyObject]
			let equalDicts = objectValues?.count == sampleDict?.count
			let linked = objectValues!["link"] as! Bool
			
			XCTAssert(linked, "Should be link of true")
			
			XCTAssert(equalDicts, "Dictionaries don't match")
		}
	}

	func testArrayInsert() {
		let table: DBTable = "table1"
		let key = "ARRAYINSERTKEY"
		let sample = "{\"numValue\":1,\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5],\"array2Value\":[\"1\",\"b\"]}"
		let sampleData = sample.data(using: String.Encoding.utf8, allowLossyConversion: false)!
		let sampleDict = (try? JSONSerialization.jsonObject(with: sampleData, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: AnyObject]
		let successful = db.setValueInTable(table, for: key, to: sample, autoDeleteAfter: nil)

		XCTAssert(successful, "setValueFailed")

		let jsonValue = db.valueFromTable(table, for: key)

		XCTAssert(jsonValue != nil, "No value returned")

		// compare dict values
		if let jsonValue = jsonValue {
			let dataValue = jsonValue.data(using: String.Encoding.utf8, allowLossyConversion: false)!
			let objectValues = (try? JSONSerialization.jsonObject(with: dataValue, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: AnyObject]
			let equalDicts = objectValues?.count == sampleDict?.count
			XCTAssert(equalDicts, "Dictionaries don't match")

			let array = objectValues!["arrayValue"] as! [Int]
			var properArray = array.filter({ $0 == 1 }).count == 1 && array.filter({ $0 == 2 }).count == 1 && array.filter({ $0 == 3 }).count == 1 && array.filter({ $0 == 4 }).count == 1 && array.filter({ $0 == 5 }).count == 1

			XCTAssert(properArray, "improper Array")

			let array2 = objectValues!["array2Value"] as! [String]
			properArray = array2.filter({ $0 == "1" }).count == 1 && array2.filter({ $0 == "b" }).count == 1

			XCTAssert(properArray, "improper Array2")
		}
	}

	func testChange() {
		let table: DBTable = "table1"
		let key = "AABBCC3"
		let firstSample = "{\"numValue\":1,\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}"
		var successful = db.setValueInTable(table, for: key, to: firstSample, autoDeleteAfter: nil)

		XCTAssert(successful, "setValueFailed")

		let sample = "{\"numValue\":2,\"arrayValue\":[6,7,8,9,10]}"
		successful = db.setValueInTable(table, for: key, to: sample, autoDeleteAfter: nil)

		XCTAssert(successful, "setValueFailed")

		let jsonValue = db.valueFromTable(table, for: key)

		XCTAssert(jsonValue != nil, "No value returned")

		// compare dict values
		if let jsonValue = jsonValue {
			let dataValue = jsonValue.data(using: String.Encoding.utf8, allowLossyConversion: false)!
			let objectValues = (try? JSONSerialization.jsonObject(with: dataValue, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: AnyObject]
			let numValue = objectValues!["numValue"] as! Int

			XCTAssert(numValue == 2, "number didn't change properly")

			let dateValue: AnyObject? = objectValues!["dateValue"]

			XCTAssert(dateValue == nil, "date still exists")

			let array = objectValues!["arrayValue"] as! [Int]
			let properArray = array.filter({ $0 == 6 }).count == 1 && array.filter({ $0 == 7 }).count == 1 && array.filter({ $0 == 8 }).count == 1 && array.filter({ $0 == 9 }).count == 1 && array.filter({ $0 == 10 }).count == 1

			XCTAssert(properArray, "improper Array")
		}
	}

	func testTableHasKey() {
		let table: DBTable = "table0"
		let sample = "{\"numValue\":2,\"arrayValue\":[6,7,8,9,10]}"

		db.setValueInTable(table, for: "testKey1", to: sample, autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: sample, autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: sample, autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: sample, autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: sample, autoDeleteAfter: nil)

		if let hasKey = db.tableHasKey(table: table, key: "testKey4") {
			XCTAssert(hasKey, "invalid test result")
		} else {
			XCTAssert(false, "bool not returned")
		}
	}

	func testKeyFetch() {
		let table: DBTable = "table2"
		let sample = "{\"numValue\":2,\"arrayValue\":[6,7,8,9,10]}"

		db.setValueInTable(table, for: "testKey1", to: sample, autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: sample, autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: sample, autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: sample, autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: sample, autoDeleteAfter: nil)

		if let keys = db.keysInTable(table, sortOrder: nil) {
			let properArray = keys.filter({ $0 == "testKey1" }).count == 1 && keys.filter({ $0 == "testKey2" }).count == 1 && keys.filter({ $0 == "testKey3" }).count == 1 && keys.filter({ $0 == "testKey4" }).count == 1 && keys.filter({ $0 == "testKey5" }).count == 1

			XCTAssert(properArray, "improper keys")
		} else {
			XCTAssert(false, "keys not returned")
		}
	}

	func testOrderedKeyFetch() {
		let table: DBTable = "table3"
		db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

		if let keys = db.keysInTable(table, sortOrder: "numValue,value2") {
			let properArray = keys[0] == "testKey4" && keys[1] == "testKey1" && keys[2] == "testKey5" && keys[3] == "testKey3" && keys[4] == "testKey2"

			XCTAssert(properArray, "improper keys")
		} else {
			XCTAssert(false, "keys not returned")
		}
	}

	func testDescendingKeyFetch() {
		let table: DBTable = "table4"
		db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)

		if let keys = db.keysInTable(table, sortOrder: "numValue desc,value2 desc") {
			let properArray = keys[0] == "testKey2" && keys[1] == "testKey3" && keys[2] == "testKey5" && keys[3] == "testKey1" && keys[4] == "testKey4"

			XCTAssert(properArray, "improper keys")
		} else {
			XCTAssert(false, "keys not returned")
		}
	}

	func testMissingKeyCondition() {
		let table: DBTable = "table51"
		db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":1}", autoDeleteAfter: nil)

		let accountCondition = DBCondition(set: 0, objectKey: "account", conditionOperator: .equal, value: "ACCT1" as AnyObject)
		if let keys = db.keysInTable(table, sortOrder: nil, conditions: [accountCondition]) {
			XCTAssert(keys.count == 0, "Keys shouldnt exist")
		} else {
			XCTAssert(false, "no keys object returned")
		}

		let keyCondition = DBCondition(set: 0, objectKey: "key", conditionOperator: .equal, value: "ACCT1" as AnyObject)
		if let keys = db.keysInTable(table, sortOrder: nil, conditions: [keyCondition]) {
			XCTAssert(keys.count == 0, "Keys shouldnt exist")
		} else {
			XCTAssert(false, "no keys object returned")
		}
	}

	func testSimpleConditionKeyFetch() {
		let table: DBTable = "table5"
		db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":1,\"account\":\"ACCT's 1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":2,\"account\":\"ACCT's 1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":3,\"account\":\"ACCT2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":4,\"account\":\"ACCT2\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)

		let accountCondition = DBCondition(set: 0, objectKey: "account", conditionOperator: .equal, value: "ACCT's 1" as AnyObject)
		let numCondition = DBCondition(set: 0, objectKey: "numValue", conditionOperator: .greaterThan, value: 1 as AnyObject)

		if let keys = db.keysInTable(table, sortOrder: nil, conditions: [accountCondition, numCondition]) {
			XCTAssert(keys.count == 1 && keys[0] == "testKey2", "invalid key")
		} else {
			XCTAssert(false, "keys not returned")
		}
	}

	func testContainsCondition() {
		let table: DBTable = "table6"
		db.setIndexedColumsForTable(table, to: ["account"])

		db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":3,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":4,\"account\":\"TEST3\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)

		let acctCondition = DBCondition(set: 0, objectKey: "account", conditionOperator: .contains, value: "ACCT" as AnyObject)
		let arrayCondition = DBCondition(set: 1, objectKey: "arrayValue", conditionOperator: .contains, value: 10 as AnyObject)

		if let keys = db.keysInTable(table, sortOrder: nil, conditions: [acctCondition, arrayCondition]) {
			let success = keys.count == 3 && (keys.filter({ $0 == "testKey1" }).count == 1 && keys.filter({ $0 == "testKey5" }).count == 1 && keys.filter({ $0 == "testKey2" }).count == 1)
			XCTAssert(success, "invalid keys")
		} else {
			XCTAssert(false, "keys not returned")
		}
	}

	func testEmptyCondition() {
		let table: DBTable = "table61"
		db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":3,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":4,\"account\":\"TEST3\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)

		let conditionArray = [DBCondition]()

		if let keys = db.keysInTable(table, sortOrder: nil, conditions: conditionArray) {
			let success = keys.count == 5
			XCTAssert(success, "invalid keys")
		} else {
			XCTAssert(false, "keys not returned")
		}
	}

	func testDeletion() {
		let table: DBTable = "table6"
		db.setValueInTable(table, for: "testKey41", to: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
		XCTAssert(db.deleteFromTable(table, for: "testKey41"), "deletion failed")
		XCTAssert(!db.tableHasKey(table: table, key: "testKey41")!, "key still exists")
	}

	func testDropTable() {
		let table: DBTable = "table7"
		db.setValueInTable(table, for: "testKey1", to: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey2", to: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey3", to: "{\"numValue\":3,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey4", to: "{\"numValue\":4,\"account\":\"TEST3\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
		db.setValueInTable(table, for: "testKey5", to: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)

		db.dropTable("table7")
		if let keys = db.keysInTable(table, sortOrder: nil) {
			XCTAssert(keys.count == 0, "keys were returned when table should be empty")
		} else {
			XCTAssert(false, "keys not returned")
		}
	}

	func testDropAllTables() {
		db.setValueInTable(DBTable(name: "table8"), for: "testKey1", to: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
		db.setValueInTable(DBTable(name: "table9"), for: "testKey2", to: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
		db.setValueInTable(DBTable(name: "table10"), for: "testKey3", to: "{\"numValue\":3,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
		db.setValueInTable(DBTable(name: "table11"), for: "testKey4", to: "{\"numValue\":4,\"account\":\"TEST3\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
		db.setValueInTable(DBTable(name: "table12"), for: "testKey5", to: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)

		db.dropAllTables()
		if let keys = db.keysInTable(DBTable(name: "table8"), sortOrder: nil) {
			XCTAssert(keys.count == 0, "keys were returned when table should be empty")
		} else {
			XCTAssert(false, "keys not returned")
		}

		if let keys = db.keysInTable(DBTable(name: "table9"), sortOrder: nil) {
			XCTAssert(keys.count == 0, "keys were returned when table should be empty")
		} else {
			XCTAssert(false, "keys not returned")
		}

		if let keys = db.keysInTable(DBTable(name: "table10"), sortOrder: nil) {
			XCTAssert(keys.count == 0, "keys were returned when table should be empty")
		} else {
			XCTAssert(false, "keys not returned")
		}
		if let keys = db.keysInTable(DBTable(name: "table11"), sortOrder: nil) {
			XCTAssert(keys.count == 0, "keys were returned when table should be empty")
		} else {
			XCTAssert(false, "keys not returned")
		}

		if let keys = db.keysInTable(DBTable(name: "table12"), sortOrder: nil) {
			XCTAssert(keys.count == 0, "keys were returned when table should be empty")
		} else {
			XCTAssert(false, "keys not returned")
		}
	}
	
	func testAutoDelete() {
		let deleteExpectation = expectation(description: "Value deleted")
		let table: DBTable = "AutoDeleteTable1"
		let key = "SimpleDeleteKey"
		let sample = "{\"numValue\":1,\"dateValue\":\"2014-11-19T18:23:42.434-05:00\"}"
		let successful = db.setValueInTable(table, for: key, to: sample, autoDeleteAfter: Date())
		
		XCTAssert(successful, "setValueFailed")

		delay(90) { 
			if var keys = self.db.keysInTable(table, sortOrder: nil) {
				keys = keys.filter({ $0 == key })
				XCTAssert(keys.count == 0, "keys were returned when table should be empty")
			} else {
				XCTAssert(false, "keys not returned")
			}
			
			deleteExpectation.fulfill()
		}
		
		waitForExpectations(timeout: 120, handler: nil)
	}
}




func delay(_ seconds: Double, closure: @escaping () -> Void) {
	DispatchQueue.main.asyncAfter(
		deadline: DispatchTime.now() + Double(Int64(seconds * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
}
