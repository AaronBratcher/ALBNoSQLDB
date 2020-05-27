//
//  Transactions.swift
//  SwiftUI App
//
//  Created by Aaron Bratcher  on 5/27/20.
//  Copyright © 2020 Aaron L. Bratcher. All rights reserved.
//

import Foundation

class TransactionResults: Identifiable {
	public typealias CustomClassValue = Transaction
	public typealias CustomClassIndex = Array<CustomClassValue>.Index

	public let id = UUID()
	private let transactions = sampleTransactions
}

extension TransactionResults: RandomAccessCollection {
	public var startIndex: CustomClassIndex { return transactions.startIndex }
	public var endIndex: CustomClassIndex { return transactions.endIndex }

	public subscript(index: CustomClassIndex) -> CustomClassValue? {
		get { if index >= 0 && index < transactions.count {
			return transactions[index]
			} else {
			return nil
			}
		}
	}
}
