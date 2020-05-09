//
//  DBObjectTests.swift
//  ALBNoSQLDBTests
//
//  Created by Aaron Bratcher on 4/10/20.
//  Copyright © 2020 Aaron Bratcher. All rights reserved.
//

import XCTest
@testable import ALBNoSQLDB

struct Transaction: DBObject {
	static let table: DBTable = "MoneyTransaction"

	var key = UUID().uuidString
	var date: Date
	var accountKey: String
	var notes: [String]?
	var amount: Int
    var purchaseOrders: [Int]?
    var purchaseDates: [Date]?
	var isNew = true
}

enum TransactionValue {
	static let key = "TKey"
	static let accountKey = "accountKey"
	static let notes = ["Note1", "Note2", "Note3"]
	static let amount = 100
    static let purchaseOrders = [1,2,3,4,5]
	static let isNew = true
}

class DBObjectTests: XCTestCase {
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

	func testSaveObject() throws {
        let date: Date = { Date() }()
        let purchaseDates = [date,date,date]

        let transaction = Transaction(key: TransactionValue.key, date: date, accountKey: TransactionValue.accountKey, notes: TransactionValue.notes, amount: TransactionValue.amount, purchaseOrders: TransactionValue.purchaseOrders, purchaseDates: purchaseDates, isNew: TransactionValue.isNew)
		transaction.save(to: db)

		guard let testTransaction = Transaction.init(db: db, key: TransactionValue.key) else { XCTFail(); return }

		let dateCompare = Calendar(identifier: .gregorian).compare(date, to: testTransaction.date, toGranularity: .nanosecond)
        let dateCompare0 = Calendar(identifier: .gregorian).compare(date, to: testTransaction.purchaseDates![0], toGranularity: .nanosecond)
        let dateCompare1 = Calendar(identifier: .gregorian).compare(date, to: testTransaction.purchaseDates![1], toGranularity: .nanosecond)
        let dateCompare2 = Calendar(identifier: .gregorian).compare(date, to: testTransaction.purchaseDates![2], toGranularity: .nanosecond)

		XCTAssertEqual(testTransaction.key, TransactionValue.key)
		XCTAssertEqual(dateCompare, ComparisonResult.orderedSame)
		XCTAssertEqual(testTransaction.accountKey, TransactionValue.accountKey)
		XCTAssertEqual(testTransaction.notes, TransactionValue.notes)
		XCTAssertEqual(testTransaction.amount, TransactionValue.amount)
        XCTAssertEqual(testTransaction.purchaseOrders, TransactionValue.purchaseOrders)
        XCTAssertEqual(dateCompare0, ComparisonResult.orderedSame)
        XCTAssertEqual(dateCompare1, ComparisonResult.orderedSame)
        XCTAssertEqual(dateCompare2, ComparisonResult.orderedSame)
		XCTAssertEqual(testTransaction.isNew, TransactionValue.isNew)
	}

	func testSaveNilValue() throws {
		let date = Date()
		let transaction = Transaction(key: TransactionValue.key, date: date, accountKey: TransactionValue.accountKey, amount: TransactionValue.amount, isNew: TransactionValue.isNew)
		transaction.save(to: db)

		guard let testTransaction = Transaction.init(db: db, key: TransactionValue.key) else { XCTFail(); return }

		XCTAssertNil(testTransaction.notes)
	}

	func testAsyncObject() throws {
		let transaction = Transaction(key: TransactionValue.key, date: Date(), accountKey: TransactionValue.accountKey, notes: TransactionValue.notes, amount: TransactionValue.amount, isNew: TransactionValue.isNew)
		transaction.save(to: db)

		let expectations = expectation(description: "DBObject Expectations")
		expectations.expectedFulfillmentCount = 1

		Transaction.loadObjectFromDB(db, for: TransactionValue.key) { (_) in
			expectations.fulfill()
		}

		waitForExpectations(timeout: 2, handler: nil)
	}
}
