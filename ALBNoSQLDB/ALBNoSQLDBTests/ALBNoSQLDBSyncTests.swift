//
//  ALBNoSQLDBSyncTests.swift
//  ALBNoSQLDB
//
//  Created by Aaron Bratcher on 1/15/15.
//  Copyright (c) 2015 Aaron Bratcher. All rights reserved.
//

import Foundation
import XCTest
@testable import ALBNoSQLDB

func dbForTestClass(className: String) -> ALBNoSQLDB {
	let pathURL = URL(fileURLWithPath: pathForDB(className: className))
	let db = ALBNoSQLDB(fileLocation: pathURL)

	return db
}

func pathForDB(className: String) -> String {
	let searchPaths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)
	let documentFolderPath = searchPaths[0]
	let dbFilePath = documentFolderPath + "/\(className).db"
	return dbFilePath
}

class ALBNoSQLDBSyncTests: XCTestCase {
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
		let path = pathForDB(className: String(describing: type(of: self)))
		let fileExists = FileManager.default.fileExists(atPath: path)
		if fileExists {
			try? FileManager.default.removeItem(atPath: path)
		}
	}

	func testEnableSyncing() {
		XCTAssert(db.enableSyncing(), "Could not enable syncing")
	}

	func testDisableSyncing() {
		if !db.enableSyncing() { return }
		XCTAssert(db.disableSyncing(), "Could not disable syncing")
	}

	func testCreateSyncFile() {
		_ = db.disableSyncing()
		db.dropAllTables()
		_ = db.enableSyncing()

		db.setValueInTable(DBTable(name: "table8"), for: "testKey1", to: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
		db.deleteFromTable(DBTable(name: "table8"), for: "testKey1")

		db.setValueInTable(DBTable(name: "table9"), for: "testKey2", to: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)

		db.setValueInTable(DBTable(name: "table9"), for: "testKey1", to: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\"}", autoDeleteAfter: nil)

		db.setValueInTable(DBTable(name: "table10"), for: "testKey3", to: "{\"numValue\":3,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
		db.setValueInTable(DBTable(name: "table10"), for: "testKey3", to: "{\"numValue\":3,\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12]}", autoDeleteAfter: nil)

		db.setValueInTable(DBTable(name: "table11"), for: "testKey4", to: "{\"numValue\":4,\"account\":\"TEST3\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
		db.deleteFromTable(DBTable(name: "table11"), for: "testKey4")

		db.setValueInTable(DBTable(name: "table12"), for: "testKey5", to: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)
		db.dropTable("table9")

		let searchPaths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)
		let documentFolderPath = searchPaths[0]
		let logFilePath = documentFolderPath + "/testSyncLog.txt"
		print(logFilePath)
		let fileURL = URL(fileURLWithPath: logFilePath)

		let (complete, lastSequence) = db.createSyncFileAtURL(fileURL, lastSequence: 0, targetDBInstanceKey: "TEST-DB-INSTANCE")

		XCTAssert(complete, "sync file not completed")
		XCTAssert(lastSequence == 10, "lastSequence is incorrect")

		// read in file and make sure it is valid JSON
		if let fileHandle = FileHandle(forReadingAtPath: logFilePath) {
			let dataValue = fileHandle.readDataToEndOfFile()
			if let _ = (try? JSONSerialization.jsonObject(with: dataValue, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: AnyObject] {
				// conversion successful
			} else {
				XCTAssert(false, "invalid sync file format")
			}
		} else {
			XCTAssert(false, "cannot open file")
		}
	}

	func testProcessSyncFile() {
		if !db.disableSyncing() {
			XCTFail()
		}

		if !db.dropAllTables() {
			XCTFail()
		}

		if !db.enableSyncing() {
			XCTFail()
		}

		// will be deleted
		db.setValueInTable(DBTable(name: "table8"), for: "testKey1", to: "{\"numValue\":10,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)

		// these entries will be deleted because of a drop table
		db.setValueInTable(DBTable(name: "table9"), for: "testKey2", to: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
		db.setValueInTable(DBTable(name: "table9"), for: "testKey3", to: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
		db.setValueInTable(DBTable(name: "table9"), for: "testKey4", to: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
		db.setValueInTable(DBTable(name: "table9"), for: "testKey5", to: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)

		// this value will be unchanged due to timeStamp
		db.setValueInTable(DBTable(name: "table10"), for: "testKey3", to: "{\"numValue\":13,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)

		// this value will be updated
		db.setValueInTable(DBTable(name: "table12"), for: "testKey5", to: "{\"numValue\":15,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)

		let syncFileContents = "{\"sourceDB\":\"58D200A048F9\",\"lastSequence\":1000,\"logEntries\":[{\"timeStamp\":\"2020-01-15T16:22:55.231-05:00\",\"key\":\"testKey1\",\"activity\":\"D\",\"tableName\":\"table8\"},{\"timeStamp\":\"2010-01-15T16:22:55.262-05:00\",\"value\":{\"addedDateTime\":\"2015-01-15T16:22:55.246-05:00\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"numValue\":3,\"updatedDateTime\":\"2015-01-15T16:22:55.258-05:00\",\"arrayValue\":[11,12]},\"key\":\"testKey3\",\"activity\":\"U\",\"tableName\":\"table10\"},{\"timeStamp\":\"2015-01-15T16:22:55.276-05:00\",\"key\":\"testKey4\",\"activity\":\"D\",\"tableName\":\"table11\"},{\"timeStamp\":\"2020-01-15T16:22:55.288-05:00\",\"value\":{\"addedDateTime\":\"2015-01-15T16:22:55.277-05:00\",\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"numValue\":5,\"updatedDateTime\":\"2015-01-15T16:22:55.277-05:00\",\"arrayValue\":[21,22,23,24,25]},\"key\":\"testKey5\",\"activity\":\"U\",\"tableName\":\"table12\"},{\"tableName\":\"table9\",\"activity\":\"X\",\"timeStamp\":\"2020-01-15T16:22:55.290-05:00\"}]}"

		let searchPaths = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)
		let documentFolderPath = searchPaths[0]
		let logFilePath = documentFolderPath + "/testSyncLog2.txt"

		FileManager.default.createFile(atPath: logFilePath, contents: nil, attributes: nil)
		if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
			fileHandle.write(syncFileContents.dataValue() as Data)
			fileHandle.closeFile()
			let fileURL = URL(fileURLWithPath: logFilePath)

			let (results, _, _) = db.processSyncFileAtURL(fileURL, syncProgress: nil)
			XCTAssert(results, "sync log not processed")

			// check for proper changes
            XCTAssert(!db.tableHasKey(table: DBTable(name: "table8"), key: "testKey1")!, "table8 still has entry")

			XCTAssert(!db.tableHasKey(table: DBTable(name: "table9"), key: "testKey2")!, "drop table 9 failed")
			XCTAssert(!db.tableHasKey(table: DBTable(name: "table9"), key: "testKey3")!, "drop table 9 failed")
			XCTAssert(!db.tableHasKey(table: DBTable(name: "table9"), key: "testKey4")!, "drop table 9 failed")
			XCTAssert(!db.tableHasKey(table: DBTable(name: "table9"), key: "testKey5")!, "drop table 9 failed")

			var jsonValue = db.valueFromTable(DBTable(name: "table10"), for: "testKey3")
			// compare dict values
			if let jsonValue = jsonValue {
				let dataValue = jsonValue.data(using: String.Encoding.utf8, allowLossyConversion: false)!
				let objectValues = (try? JSONSerialization.jsonObject(with: dataValue, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: AnyObject]
				let numValue = objectValues!["numValue"] as! Int

				XCTAssert(numValue == 13, "number unexpectedly got changed")
			}

			jsonValue = db.valueFromTable(DBTable(name: "table12"), for: "testKey5")
			// compare dict values
			if let jsonValue = jsonValue {
				let dataValue = jsonValue.data(using: String.Encoding.utf8, allowLossyConversion: false)!
				let objectValues = (try? JSONSerialization.jsonObject(with: dataValue, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: AnyObject]
				let numValue = objectValues!["numValue"] as! Int

				XCTAssert(numValue == 5, "number was not changed")


			}
		} else {
			XCTAssert(false, "unable to create log file")
		}
	}
}

extension String {
	func dataValue() -> Data {
		return data(using: .utf8, allowLossyConversion: false)!
	}
}
