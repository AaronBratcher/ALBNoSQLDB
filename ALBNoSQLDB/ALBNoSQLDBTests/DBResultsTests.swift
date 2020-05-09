//
//  DBResultsTests.swift
//  ALBNoSQLDBTests
//
//  Created by Aaron Bratcher  on 5/9/20.
//  Copyright © 2020 Aaron Bratcher. All rights reserved.
//

import XCTest
@testable import ALBNoSQLDB

class DBResultsTests: XCTestCase {
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


	func testDBResults() throws {
		let date = Date()
		let keys = ["1", "2", "3"]

		var transaction = Transaction(key: keys[0], date: date, accountKey: "A1", notes: TransactionValue.notes, amount: TransactionValue.amount, purchaseOrders: TransactionValue.purchaseOrders, isNew: TransactionValue.isNew)
		transaction.save(to: db)

		transaction = Transaction(key: keys[1], date: date, accountKey: "A2", notes: TransactionValue.notes, amount: TransactionValue.amount, purchaseOrders: TransactionValue.purchaseOrders, isNew: TransactionValue.isNew)
		transaction.save(to: db)

		transaction = Transaction(key: keys[2], date: date, accountKey: "A3", notes: TransactionValue.notes, amount: TransactionValue.amount, purchaseOrders: TransactionValue.purchaseOrders, isNew: TransactionValue.isNew)
		transaction.save(to: db)

		let transactions = DBResults<Transaction>(db: db, keys: keys)
		XCTAssertEqual(transactions.count, 3)
		XCTAssertEqual(transactions[0]?.accountKey, "A1")
		XCTAssertEqual(transactions[1]?.accountKey, "A2")
		XCTAssertEqual(transactions[2]?.accountKey, "A3")
	}
}
