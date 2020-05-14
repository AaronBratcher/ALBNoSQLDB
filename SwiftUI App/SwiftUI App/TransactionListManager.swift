//
//  TransactionListManager.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher  on 5/14/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import Foundation
import Combine
import ALBNoSQLDB

class TransactionListManager: ObservableObject {
    @Published var transactions = DBResults<Transaction>()
    @Published var searchText = "" {
        didSet {
            updateTransactions()
        }
    }

    private var cancellableSubscription: AnyCancellable?
    private var db: ALBNoSQLDB

    init(db: ALBNoSQLDB = ALBNoSQLDB.shared) {
        self.db = db
        updateTransactions()
    }

    init(keys: [String]) {
        transactions = DBResults<Transaction>(
    }

    func updateTransactions() {
        let condition = DBCondition(set: 0, objectKey: "description", conditionOperator: .contains, value: searchText as AnyObject)

        let publisher: DBResultsPublisher<Transaction> = db.publisher(sortOrder: "date desc", conditions: [condition])
        cancellableSubscription = publisher.sink(receiveCompletion: {_ in }, receiveValue: { (results) in
            self.transactions = results
        })
    }
}
