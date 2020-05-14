//
//  SampleTransactions.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher  on 5/13/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import Foundation
import ALBNoSQLDB

let sampleTransactions: [Transaction] = [
    Transaction(key: "T1", date: ALBNoSQLDB.dateValueForString("2020-04-13T18:56:43.468-04:00")!, description: "Kroger", amount: 12315),
    Transaction(key: "T2", date: ALBNoSQLDB.dateValueForString("2020-04-13T10:11:43.468-04:00")!, description: "Starbucks", amount: 425),
    Transaction(key: "T3", date: ALBNoSQLDB.dateValueForString("2020-04-15T00:56:43.468-04:00")!, description: "Mortgage", amount: 89500),
    Transaction(key: "T4", date: ALBNoSQLDB.dateValueForString("2020-04-16T08:00:43.468-04:00")!, description: "Electric", amount: 6387),
    Transaction(key: "T5", date: ALBNoSQLDB.dateValueForString("2020-04-16T08:30:17.468-04:00")!, description: "Cell Phone", amount: 12542)
]
