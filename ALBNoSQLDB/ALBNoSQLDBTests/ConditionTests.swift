//
//  ALBNoSQLDBDeletionTests.swift
//  ALBNoSQLDBTests
//
//  Created by Aaron Bratcher on 5/12/19.
//  Copyright © 2019 Aaron Bratcher. All rights reserved.
//

import Foundation
import XCTest
@testable import ALBNoSQLDB

class ConditionTests: XCTestCase {
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
		print(path)
		let fileExists = FileManager.default.fileExists(atPath: path)
		if fileExists {
			try? FileManager.default.removeItem(atPath: path)
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
		db.setIndexesForTable(table, to: ["account"])
		
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
	
	func testValidateObjects() {
		let table: DBTable = "Transactions"
		let key = UUID().uuidString
		let dict = [
			"key": key
			, "accountKey": "Checking"
			, "locationKey" :"Kroger"
			, "categoryKey": "Food"
		]
		
		let data = try! JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
		let json = String(data: data, encoding: .utf8)!
		db.setValueInTable(table, for: key, to: json)
		
		var conditions: [DBCondition] = []
		conditions.append(DBCondition(set: 0, objectKey: "accountKey", conditionOperator: .equal, value: "Checking" as AnyObject))
		conditions.append(DBCondition(set: 0, objectKey: "locationKey", conditionOperator: .equal, value: "Kroger" as AnyObject))
		
		conditions.append(DBCondition(set: 1, objectKey: "accountKey", conditionOperator: .equal, value: "Checking" as AnyObject))
		conditions.append(DBCondition(set: 1, objectKey: "note", conditionOperator: .equal, value: "Kroger" as AnyObject))
		
		if let keys = db.keysInTable(table, sortOrder: nil, conditions: conditions, validateObjects: true) {
			XCTAssert(keys.count == 1)
		} else {
			XCTAssert(false, "keys not returned")
		}
	}
}
