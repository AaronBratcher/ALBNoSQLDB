//
//  DBModels.swift
//  ALBNoSQLDB
//
//  Created by Aaron Bratcher  on 5/1/20.
//  Copyright © 2020 Aaron Bratcher. All rights reserved.
//

import Foundation

public typealias BoolResults = Result<Bool, DBError>
public typealias KeyResults = Result<[String], DBError>
public typealias RowResults = Result<[DBRow], DBError>
public typealias JsonResults = Result<String, DBError>
public typealias DictResults = Result<[String: AnyObject], DBError>

/**
DBTable is used to identify the table data is stored in
*/
public struct DBTable: Equatable {
	let name: String

	public init(name: String) {
		assert(name != "", "name cannot be empty")
		assert(!ALBNoSQLDB.reservedTable(name), "reserved table")
		self.name = name
	}
}

extension DBTable: ExpressibleByStringLiteral {
	public init(stringLiteral name: String) {
		self.init(name: name)
	}
}

extension DBTable: CustomStringConvertible {
	public var description: String {
		return name
	}
}

/**
DBCommandToken is returned by asynchronous methods. Call the token's cancel method to cancel the command before it executes.
*/
public struct DBCommandToken {
	private weak var database: ALBNoSQLDB?
	private let identifier: UInt

	init(database: ALBNoSQLDB, identifier: UInt) {
		self.database = database
		self.identifier = identifier
	}

	/**
    Cancel the asynchronous command before it executes

    - returns: Bool Returns if the cancel was successful.
    */
	@discardableResult
	public func cancel() -> Bool {
		guard let database = database else { return false }
		return database.dequeueCommand(identifier)
	}
}

public enum DBConditionOperator: String {
	case equal = "="
	case notEqual = "<>"
	case lessThan = "<"
	case greaterThan = ">"
	case lessThanOrEqual = "<="
	case greaterThanOrEqual = ">="
	case contains = "..."
	case inList = "()"
}

public struct DBCondition {
	public var set = 0
	public var objectKey = ""
	public var conditionOperator = DBConditionOperator.equal
	public var value: AnyObject

	public init(set: Int, objectKey: String, conditionOperator: DBConditionOperator, value: AnyObject) {
		self.set = set
		self.objectKey = objectKey
		self.conditionOperator = conditionOperator
		self.value = value
	}
}

public struct DBRow {
	public var values = [AnyObject?]()
}

public enum DBError: Error {
	case cannotWriteToFile
	case diskError
	case damagedFile
	case cannotOpenFile
	case tableNotFound
	case other(Int)
}

extension DBError: RawRepresentable {
	public typealias RawValue = Int

	public init(rawValue: RawValue) {
		switch rawValue {
		case 8: self = .cannotWriteToFile
		case 10: self = .diskError
		case 11: self = .damagedFile
		case 14: self = .cannotOpenFile
		case -1: self = .tableNotFound
		default: self = .other(rawValue)
		}
	}

	public var rawValue: RawValue {
		switch self {
		case .cannotWriteToFile: return 8
		case .diskError: return 10
		case .damagedFile: return 11
		case .cannotOpenFile: return 14
		case .tableNotFound: return -1
		case .other(let value): return value
		}
	}
}
