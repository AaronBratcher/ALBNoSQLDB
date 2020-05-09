//
//  PublisherTests.swift
//  ALBNoSQLDBTests
//
//  Created by Aaron Bratcher  on 5/3/20.
//  Copyright © 2020 Aaron Bratcher. All rights reserved.
//

import XCTest
import Combine
@testable import ALBNoSQLDB

class PublisherTests: XCTestCase {
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

	func testCreatePublisher() throws {
		addObjectsToDB()

		let expectations = expectation(description: "PublisherExpectations")
		expectations.expectedFulfillmentCount = 3

		var index = 0
		let publisher: DBResultsPublisher<Transaction> = db.publisher()
		let subscription = publisher.sink(receiveCompletion: { _ in }) { ( results) in
			if index == 1 {
				XCTAssertEqual(results.count, 9)
			}

            if index == 2 {
                XCTAssertEqual(results.count, 10)
            }
			index += 1
			expectations.fulfill()
		}

        DispatchQueue.main.asyncAfter(wallDeadline: .now()+1) {
            let transaction = Transaction(key: "K10", date: Date(), accountKey: "A1", amount: 100, isNew: true)
            transaction.save(to: self.db)

        }

		waitForExpectations(timeout: 15, handler: nil)
	}

    func testUpdatedPublishers() throws {
        addObjectsToDB()

        let expectations = expectation(description: "PublisherExpectations")
        expectations.expectedFulfillmentCount = 7
        let account1Condition = DBCondition(set: 0, objectKey: "accountKey", conditionOperator: .equal, value: "A1" as AnyObject)
        let account2Condition = DBCondition(set: 0, objectKey: "accountKey", conditionOperator: .equal, value: "A2" as AnyObject)

        var index1 = 0
        var index2 = 0
        let publisher1: DBResultsPublisher<Transaction> = db.publisher(conditions: [account1Condition])
        let subscription1 = publisher1.sink(receiveCompletion: { _ in }) { ( results) in
            if index1 == 1 {
                XCTAssertEqual(results.count, 5)
            }

            if index1 == 2 {
                XCTAssertEqual(results.count, 6)
            }

            if index1 == 3 {
                XCTAssertEqual(results.count, 5)
            }
            index1 += 1
            expectations.fulfill()
        }

        let publisher2: DBResultsPublisher<Transaction> = db.publisher(conditions: [account2Condition])
        let subscription2 = publisher2.sink(receiveCompletion: { _ in }) { ( results) in
            if index2 == 1 {
                XCTAssertEqual(results.count, 4)
            }

            if index2 == 2 {
                XCTAssertEqual(results.count, 5)
            }
            index2 += 1
            expectations.fulfill()
        }

        DispatchQueue.main.asyncAfter(wallDeadline: .now()+1) {
            var transaction = Transaction(key: "K10", date: Date(), accountKey: "A1", amount: 100, isNew: true)
            transaction.save(to: self.db)

            transaction = Transaction(key: "K11", date: Date(), accountKey: "A2", amount: 100, isNew: true)
            transaction.save(to: self.db)
        }

        DispatchQueue.main.asyncAfter(wallDeadline: .now()+2) {
            self.db.deleteFromTable(Transaction.table, for: "K10")
        }


        waitForExpectations(timeout: 15, handler: nil)
    }

	func addObjectsToDB() {
		var transaction = Transaction(key: "K1", date: Date(), accountKey: "A1", amount: 100, isNew: true)
		transaction.save(to: db)

		transaction = Transaction(key: "K2", date: Date(), accountKey: "A1", amount: 200, isNew: true)
		transaction.save(to: db)

		transaction = Transaction(key: "K3", date: Date(), accountKey: "A1", amount: 300, isNew: true)
		transaction.save(to: db)

		transaction = Transaction(key: "K4", date: Date(), accountKey: "A1", amount: 400, isNew: true)
		transaction.save(to: db)

		transaction = Transaction(key: "K5", date: Date(), accountKey: "A1", amount: 500, isNew: true)
		transaction.save(to: db)

		transaction = Transaction(key: "K6", date: Date(), accountKey: "A2", amount: 600, isNew: true)
		transaction.save(to: db)

		transaction = Transaction(key: "K7", date: Date(), accountKey: "A2", amount: 700, isNew: true)
		transaction.save(to: db)

		transaction = Transaction(key: "K8", date: Date(), accountKey: "A2", amount: 800, isNew: true)
		transaction.save(to: db)

		transaction = Transaction(key: "K9", date: Date(), accountKey: "A2", amount: 900, isNew: true)
		transaction.save(to: db)
	}
}
