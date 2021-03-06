//
//  Transaction.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher on 5/13/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import Foundation
import ALBNoSQLDB

struct Transaction: DBObject {
	static var table: DBTable = "Transactions"
	var key = UUID().uuidString

	var date = Date()
	var description = ""
	var amount = 0
}

extension Transaction: Identifiable, Hashable {
	typealias ID = String

	var id: ID {
		return key
	}
}
