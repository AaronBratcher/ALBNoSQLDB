//
//  TransactionViewModel.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher on 5/17/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import Foundation
import ALBNoSQLDB

class TransactionViewModel: ObservableObject {
	@Published var date = Date()
	@Published var description = ""
	@Published var amount = ""

	var transaction: Transaction!

	var isValidAmount: Bool {
		return amount.count > 0 && amount.isCurrencyString
	}

	init(transaction: Transaction? = nil) {
		self.transaction = transaction
		guard let transaction = transaction else { return }

		initialize(with: transaction)
	}

	private func initialize(with transaction: Transaction) {
		date = transaction.date
		description = transaction.description
		amount = transaction.amount.formatted()
	}

	func save() {
		if transaction == nil {
			transaction = Transaction()
		}

		transaction.date = date
		transaction.description = description
		transaction.amount = amount.intValue()

		transaction.save(to: ALBNoSQLDB.shared)
	}
}
