//
//  DBCursor.swift
//  ALBNoSQLDB
//
//  Created by Aaron Bratcher on 4/10/20.
//  Copyright © 2020 Aaron Bratcher. All rights reserved.
//

import Foundation

public class DBResults<T: DBObject>: Identifiable {
	public typealias CustomClassValue = T
	public typealias CustomClassIndex = Array<CustomClassValue>.Index

	public let id = UUID()
	private let keys: [String]
	private let db: ALBNoSQLDB

	public init() {
		db = ALBNoSQLDB.shared
		keys = []
	}

	public init(db: ALBNoSQLDB, keys: [String]) {
		self.db = db
		self.keys = keys
	}
}

extension DBResults: RandomAccessCollection, MutableCollection {
	public var startIndex: CustomClassIndex { return keys.startIndex }
	public var endIndex: CustomClassIndex { return keys.endIndex }

	public subscript(index: CustomClassIndex) -> CustomClassValue? {
		get { if index >= 0 && index < keys.count {
			return T(db: db, key: keys[index])
			} else {
			return nil
			}
		}

		set { }
	}
}
