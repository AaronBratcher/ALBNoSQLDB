//
// ALBNoSQLswift
//
// Created by Aaron Bratcher on 01/08/2015.
// Copyright (c) 2015 – 2019 Aaron L Bratcher. All rights reserved.
//

import Foundation

// MARK: - Definitions
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
	public init(stringLiteral value: String) {
		name = value
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

	public init() {
		identifier = 0
	}

	fileprivate init(database: ALBNoSQLDB, identifier: UInt) {
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

// MARK: - Class Definition
public final class ALBNoSQLDB {
	fileprivate enum ValueType: String {
		case textArray = "stringArray"
		case intArray
		case doubleArray
		case text
		case int
		case double
		case bool
		case null
		case unknown

		static func fromRaw(_ rawValue: String) -> ValueType {
			if let valueType = ValueType(rawValue: rawValue.lowercased()) {
				return valueType
			}

			return .unknown
		}
	}

	public static let shared = ALBNoSQLDB()

	/**
	Used for testing purposes. This should never be enabled in production.
	*/
	public var isDebugging = false {
		didSet {
			_SQLiteCore.isDebugging = isDebugging
		}
	}

	/**
	The number of seconds to wait after inactivity before automatically closing the file. File is automatically opened for next activity.
	*/
	public var autoCloseTimeout = 0

	public static var dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.calendar = Calendar(identifier: .gregorian)
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'.'SSSZZZZZ"

		return dateFormatter
	}()

	// MARK: - Private properties
	private struct DBTables {
		private var tables: [DBTable] = []
		static let tableQueue = DispatchQueue(label: "com.AaronLBratcher.ALBNoSQLTableQueue", attributes: [])

		func allTables() -> [DBTable] {
			return tables
		}

		mutating func addTable(_ table: DBTable) {
			DBTables.tableQueue.sync {
				tables.append(DBTable(name: table.name))
			}
		}

		mutating func dropTable(_ table: DBTable) {
			DBTables.tableQueue.sync {
				tables = tables.filter({ $0 != table })
			}
		}

		mutating func dropAllTables() {
			DBTables.tableQueue.sync {
				tables = []
			}
		}

		func hasTable(_ table: DBTable) -> Bool {
			var exists = false

			DBTables.tableQueue.sync {
				exists = tables.filter({ $0 == table }).isNotEmpty
			}

			return exists
		}
	}

	private var _SQLiteCore = SQLiteCore()
	private var _lock = DispatchSemaphore(value: 0)
	private var _dbFileLocation: URL?
	private var _instanceKey = ""
	private var _tables = DBTables()
	private var _indexes = [String: [String]]()
	private let _dbQueue = DispatchQueue(label: "com.AaronLBratcher.ALBNoSQLDBQueue", qos: .userInitiated)
	private var _syncingEnabled = false
	private var _unsyncedTables = [String]()
	private let _deletionQueue = DispatchQueue(label: "com.AaronLBratcher.ALBNoSQLDBDeletionQueue", attributes: [])
	private lazy var _autoDeleteTimer: RepeatingTimer = {
		return RepeatingTimer(timeInterval: 60) {
			self.autoDelete()
		}
	}()

	// MARK: - Init
	/**
	Instantiates an instance of ALBNoSQLDB
	
	- parameter location: Optional file location if different than the default.
	*/
	public init(fileLocation: URL? = nil) {
		_dbFileLocation = fileLocation
		_SQLiteCore.start()
	}

	// MARK: - Open / Close
	/**
	Opens the database file.
	
	- parameter location: Optional file location if different than the default.
	
	- returns: Bool Returns if the database could be successfully opened.
	*/
	public func open(_ location: URL? = nil) -> Bool {
		let dbFileLocation = location ?? _dbFileLocation ?? URL(fileURLWithPath: defaultFileLocation())
		// if we already have a db file open at a different location, close it first
		if _SQLiteCore.isOpen && _dbFileLocation != dbFileLocation {
			close()
		}

		if let location = location {
			_dbFileLocation = location
		}

		let openResults = openDB()
		if case .success(_) = openResults {
			return true
		} else {
			return false
		}
	}

	/**
	Close the database.
	*/
	public func close() {
		_autoDeleteTimer.suspend()
		_dbQueue.sync { () -> Void in
			_SQLiteCore.close()
		}
	}

	// MARK: - Keys

	/**
	Checks if the given table contains the given key.
	
	- parameter table: The table to search.
	- parameter key: The key to look for.
	
	- returns: Bool? Returns if the key exists in the table. Is nil when database could not be opened or other error occured.
	*/
	@available( *, deprecated, message: "use tableHasKey that accepts DBTable for first parameter")
	public func tableHasKey(table: String, key: String) -> Bool? {
		return tableHasKey(table: DBTable(name: table), key: key)
	}

	/**
	Checks if the given table contains the given key.
	
	- parameter table: The table to search.
	- parameter key: The key to look for.
	
	- returns: Bool? Returns if the key exists in the table. Is nil when database could not be opened or other error occured.
	*/
	public func tableHasKey(table: DBTable, key: String) -> Bool? {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return nil
		}

		if !_tables.hasTable(table) {
			return false
		}

		let sql = "select 1 from \(table) where key = '\(key)'"
		let results = sqlSelect(sql)
		if let results = results {
			return results.isNotEmpty
		}

		return nil
	}

	/**
	Asynchronously checks if the given table contains the given key.
	
	- parameter table: The table to search.
	- parameter key: The key to look for.
	- parameter queue: Dispatch queue to use when running the completion closure. Default value is main queue.
	- parameter completion: Closure to use for results.
	
	- returns: DBActivityToken Returns a DBCommandToken that can be used to cancel the command before it executes If the database file cannot be opened nil is returned.
	*/
	@discardableResult
	public func tableHasKey(table: DBTable, key: String, queue: DispatchQueue? = nil, completion: @escaping (BoolResults) -> Void) -> DBCommandToken? {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return nil
		}

		if !_tables.hasTable(table) {
			let dispatchQueue = queue ?? DispatchQueue.main
			dispatchQueue.async {
				completion(Result<Bool, DBError>.success(false))
			}
			return DBCommandToken(database: self, identifier: 0)
		}

		let sql = "select 1 from \(table) where key = '\(key)'"
		let blockReference = _SQLiteCore.sqlSelect(sql, completion: { (rowResults) -> Void in
			let dispatchQueue = queue ?? DispatchQueue.main
			dispatchQueue.async {
				let results: BoolResults

				switch rowResults {
				case .success(let rows):
					results = .success(rows.isNotEmpty)

				case .failure(let error):
					results = .failure(error)
				}

				completion(results)
			}
		})

		return DBCommandToken(database: self, identifier: blockReference)
	}

	/**
	Returns an array of keys from the given table sorted in the way specified matching the given conditions. All conditions in the same set are ANDed together. Separate sets are ORed against each other.  (set:0 AND set:0 AND set:0) OR (set:1 AND set:1 AND set:1) OR (set:2)
	
	Unsorted Example:
	
	let accountCondition = DBCondition(set:0,objectKey:"account",conditionOperator:.equal, value:"ACCT1")
	if let keys = ALBNoSQLkeysInTable("table1", sortOrder:nil, conditions:accountCondition) {
	// use keys
	} else {
	// handle error
	}
	
	- parameter table: The table to return keys from.
	- parameter sortOrder: Optional string that gives a comma delimited list of properties to sort by.
	- parameter conditions: Optional array of DBConditions that specify what conditions must be met.
	
	- returns: [String]? Returns an array of keys from the table. Is nil when database could not be opened or other error occured.
	*/
	@available( *, deprecated, message: "use keysInTable that accepts DBTable for first parameter")
	public func keysInTable(_ table: String, sortOrder: String? = nil, conditions: [DBCondition]? = nil) -> [String]? {
		return keysInTable(DBTable(name: table), sortOrder: sortOrder, conditions: conditions)
	}

	/**
	Returns an array of keys from the given table sorted in the way specified matching the given conditions. All conditions in the same set are ANDed together. Separate sets are ORed against each other.  (set:0 AND set:0 AND set:0) OR (set:1 AND set:1 AND set:1) OR (set:2)
	
	Unsorted Example:
	
	let accountCondition = DBCondition(set:0,objectKey:"account",conditionOperator:.equal, value:"ACCT1")
	if let keys = ALBNoSQLkeysInTable("table1", sortOrder:nil, conditions:accountCondition) {
	// use keys
	} else {
	// handle error
	}
	
	- parameter table: The DBTable to return keys from.
	- parameter sortOrder: Optional string that gives a comma delimited list of properties to sort by.
	- parameter conditions: Optional array of DBConditions that specify what conditions must be met.
	- parameter validateObjects: Optional bool that condition sets will be validated against the table. Any set that refers to json objects that do not exist in the table will be ignored. Default value is false.
	
	- returns: [String]? Returns an array of keys from the table. Is nil when database could not be opened or other error occured.
	*/
	public func keysInTable(_ table: DBTable, sortOrder: String? = nil, conditions: [DBCondition]? = nil, validateObjecs: Bool = false) -> [String]? {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return nil
		}

		if !_tables.hasTable(table) {
			return []
		}

		guard let sql = keysInTableSQL(table: table, sortOrder: sortOrder, conditions: conditions, validateObjecs: validateObjecs) else { return [] }

		if let results = sqlSelect(sql) {
			return results.map({ $0.values[0] as! String })
		}

		return nil
	}

	/**
	Asynchronously returns the keys in the given table.
	
	Runs a query asynchronously and calls the completion closure with the results. Successful results are keys from the given table sorted in the way specified matching the given conditions. All conditions in the same set are ANDed together. Separate sets are ORed against each other.  (set:0 AND set:0 AND set:0) OR (set:1 AND set:1 AND set:1) OR (set:2)
	
	Unsorted Example:
	
	let accountCondition = DBCondition(set:0,objectKey:"account",conditionOperator:.equal, value:"ACCT1")
	if let keys = ALBNoSQLkeysInTable("table1", sortOrder:nil, conditions:accountCondition) {
	// use keys
	} else {
	// handle error
	}
	
	- parameter table: The table to return keys from.
	- parameter sortOrder: Optional string that gives a comma delimited list of properties to sort by.
	- parameter conditions: Optional array of DBConditions that specify what conditions must be met.
	- parameter validateObjects: Optional bool that condition sets will be validated against the table. Any set that refers to json objects that do not exist in the table will be ignored. Default value is false.
	- parameter queue: Optional dispatch queue to use when running the completion closure. Default value is main queue.
	- parameter completion: Closure with DBRowResults.
	
	- returns: DBCommandToken that can be used to cancel the command before it executes If the database file cannot be opened nil is returned.
	*/

	@discardableResult
	public func keysInTable(_ table: DBTable, sortOrder: String? = nil, conditions: [DBCondition]? = nil, validateObjecs: Bool = false, queue: DispatchQueue? = nil, completion: @escaping (KeyResults) -> Void) -> DBCommandToken? {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return nil
		}

		if !_tables.hasTable(table) {
			completion(KeyResults.success([]))
			return DBCommandToken(database: self, identifier: 0)
		}

		guard let sql = keysInTableSQL(table: table, sortOrder: sortOrder, conditions: conditions, validateObjecs: validateObjecs) else { return nil }

		let blockReference = _SQLiteCore.sqlSelect(sql, completion: { (rowResults) -> Void in
			let dispatchQueue = queue ?? DispatchQueue.main
			dispatchQueue.async {
				let results: KeyResults

				switch rowResults {
				case .success(let rows):
					results = .success(rows.map({ $0.values[0] as! String }))

				case .failure(let error):
					results = .failure(error)
				}

				completion(results)
			}
		})

		return DBCommandToken(database: self, identifier: blockReference)
	}

	// MARK: - Indexing
	/**
	Sets the indexes desired for a given table.
	
	Example:
	
	ALBNoSQLsetTableIndexes(table: kTransactionsTable, indexes: ["accountKey","date"]) // index accountKey and date each individually
	
	- parameter table: The table to return keys from.
	- parameter indexes: An array of table properties to be indexed. An array entry can be compound.
	*/
	@available( *, deprecated, renamed: "setIndexesForTable")
	public func setTableIndexes(table: String, indexes: [String]) {
		_indexes[table] = indexes
		let openResults = openDB()
		if case .success(_) = openResults {
			createIndexesForTable(DBTable(name: table))
		}
	}

	/**
	Sets the indexes desired for a given table.
	
	Example:
	
	ALBNoSQLsetTableIndexes(table: kTransactionsTable, indexes: ["accountKey","date"]) // index accountKey and date each individually
	
	- parameter table: The table to return keys from.
	- parameter indexes: An array of table properties to be indexed. An array entry can be compound.
	*/
	@discardableResult
	public func setIndexesForTable(_ table: DBTable, to indexes: [String]) -> BoolResults {
		let openResults = openDB()
		if case .success(_) = openResults {
			_indexes[table.name] = indexes
			// TODO: Return results from call
			createIndexesForTable(table)
		}

		return openResults
	}

	// MARK: - Set Values
	/**
	Sets the value of an entry in the given table for a given key optionally deleted automatically after a given date. Supported values are dictionaries that consist of String, Int, Double and arrays of these. If more complex objects need to be stored, a string value of those objects need to be stored.
	
	Example:
	
	if !ALBNoSQLsetValue(table: "table5", key: "testKey1", value: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil) {
	// handle error
	}
	
	- parameter table: The table to return keys from.
	- parameter key: The key for the entry.
	- parameter value: A JSON string representing the value to be stored. Top level object provided must be a dictionary. If a key object is in the value, it will be ignored.
	- parameter autoDeleteAfter: Optional date of when the value should be automatically deleted from the table.
	
	- returns: Bool If the value was set successfully.
	*/
	@discardableResult
	@available( *, deprecated, renamed: "setValueInTable")
	public func setValue(table: String, key: String, value: String, autoDeleteAfter: Date? = nil) -> Bool {
		return setValueInTable(DBTable(name: table), for: key, to: value, autoDeleteAfter: autoDeleteAfter)
	}

	/**
	Sets the value of an entry in the given table for a given key optionally deleted automatically after a given date. Supported values are dictionaries that consist of String, Int, Double and arrays of these. If more complex objects need to be stored, a string value of those objects need to be stored.
	
	Example:
	
	if !ALBNoSQLsetValue(table: "table5", key: "testKey1", value: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil) {
	// handle error
	}
	
	- parameter table: The table to return keys from.
	- parameter key: The key for the entry.
	- parameter value: A JSON string representing the value to be stored. Top level object provided must be a dictionary. If a key object is in the value, it will be ignored.
	- parameter autoDeleteAfter: Optional date of when the value should be automatically deleted from the table.
	
	- returns: Bool If the value was set successfully.
	*/
	@discardableResult
	public func setValueInTable(_ table: DBTable, for key: String, to value: String, autoDeleteAfter: Date? = nil) -> Bool {
		assert(key != "", "key must be provided")
		assert(value != "", "value must be provided")

		let dataValue = value.data(using: .utf8)
		let objectValues = (try? JSONSerialization.jsonObject(with: dataValue!, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: AnyObject]
		assert(objectValues != nil, "Value must be valid JSON string that is a dictionary for the top-level object")

		let now = ALBNoSQLDB.stringValueForDate(Date())
		let deleteDateTime = (autoDeleteAfter == nil ? "NULL" : "'" + ALBNoSQLDB.stringValueForDate(autoDeleteAfter!) + "'")

		return setValue(table: table, key: key, objectValues: objectValues!, addedDateTime: now, updatedDateTime: now, deleteDateTime: deleteDateTime, sourceDB: _instanceKey, originalDB: _instanceKey)
	}

	// MARK: - Return Values
	/**
	Returns the JSON value of what was stored for a given table and key.
	
	Example:
	if let jsonValue = ALBNoSQLvalueForKey(table: "table1", key: "58D200A048F9") {
	// process JSON text
	} else {
	// handle error
	}
	
	- parameter table: The table to return keys from.
	- parameter key: The key for the entry.
	
	- returns: JSON value of what was stored. Is nil when database could not be opened or other error occured.
	*/
	@available( *, deprecated, renamed: "valueFromTable")
	public func valueForKey(table: String, key: String) -> String? {
		return valueFromTable(DBTable(name: table), for: key)
	}

	/**
	Returns the JSON value of what was stored for a given table and key.
	
	Example:
	if let jsonValue = ALBNoSQLvalueForKey(table: "table1", key: "58D200A048F9") {
	// process JSON text
	} else {
	// handle error
	}
	
	- parameter table: The table to return keys from.
	- parameter key: The key for the entry.
	
	- returns: JSON value of what was stored. Is nil when database could not be opened or other error occured.
	*/
	public func valueFromTable(_ table: DBTable, for key: String) -> String? {
		if let dictionaryValue = dictValueFromTable(table, for: key) {
			let dataValue = try? JSONSerialization.data(withJSONObject: dictionaryValue, options: JSONSerialization.WritingOptions(rawValue: 0))
			let jsonValue = String(data: dataValue!, encoding: .utf8)
			return jsonValue! as String
		}

		return nil
	}

	/**
	Asynchronously returns the value for a given table and key.
	
	Runs a query asynchronously and calls the completion closure with the results. Successful result is a String.
	
	- parameter table: The table to return keys from.
	- parameter key: The key for the entry.
	- parameter queue: Optional dispatch queue to use when running the completion closure. Default value is main queue.
	- parameter completion: Closure to use for JSON results.
	
	- returns: Returns a DBCommandToken that can be used to cancel the command before it executes. If the database file cannot be opened or table does not exist nil is returned.
	
	*/
	@discardableResult
	public func valueFromTable(_ table: DBTable, for key: String, queue: DispatchQueue? = nil, completion: @escaping (JsonResults) -> Void) -> DBCommandToken? {
		let openResults = openDB()
		if case .failure(_) = openResults, !_tables.hasTable(table) {
			return nil
		}

		let (sql, columns) = dictValueForKeySQL(table: table, key: key, includeDates: false)

		let blockReference = _SQLiteCore.sqlSelect(sql, completion: { [weak self] (rowResults) -> Void in
			guard let self = self else { return }

			let dispatchQueue = queue ?? DispatchQueue.main
			dispatchQueue.async {
				let results: Result<String, DBError>

				switch rowResults {
				case .success(let rows):
					guard let dictionaryValue = self.dictValueResults(table: table, key: key, results: rows, columns: columns)
						, let dataValue = try? JSONSerialization.data(withJSONObject: dictionaryValue, options: JSONSerialization.WritingOptions(rawValue: 0))
						, let jsonValue = String(data: dataValue, encoding: .utf8)
						else {
						results = .failure(.other(0))
						completion(results)
						return
					}

					results = .success(jsonValue)

				case .failure(let error):
					results = .failure(error)
				}

				completion(results)
			}
		})

		return DBCommandToken(database: self, identifier: blockReference)
	}

	/**
	Returns the dictionary value of what was stored for a given table and key.
	
	Example:
	if let dictValue = ALBNoSQLdictValueForKey(table: "table1", key: "58D200A048F9") {
	// process dictionary
	} else {
	// handle error
	}
	
	- parameter table: The table to return keys from.
	- parameter key: The key for the entry.
	
	- returns: [String:AnyObject]? Dictionary value of what was stored. Is nil when database could not be opened or other error occured.
	*/
	@available( *, deprecated, renamed: "dictValueFromTable")
	public func dictValueForKey(table: String, key: String) -> [String: AnyObject]? {
		return dictValueFromTable(DBTable(name: table), for: key, includeDates: false)
	}

	/**
	Returns the dictionary value of what was stored for a given table and key.
	
	Example:
	if let dictValue = ALBNoSQLdictValueForKey(table: "table1", key: "58D200A048F9") {
	// process dictionary
	} else {
	// handle error
	}
	
	- parameter table: The table to return keys from.
	- parameter key: The key for the entry.
	
	- returns: [String:AnyObject]? Dictionary value of what was stored. Is nil when database could not be opened or other error occured.
	*/
	public func dictValueFromTable(_ table: DBTable, for key: String) -> [String: AnyObject]? {
		return dictValueFromTable(table, for: key, includeDates: false)
	}

	/**
	Returns the dictionary value of what was stored for a given table and key.
	
	Example:
	if let dictValue = ALBNoSQLdictValueForKey(table: "table1", key: "58D200A048F9") {
	// process dictionary
	} else {
	// handle error
	}
	
	- parameter table: The table to return keys from.
	- parameter key: The key for the entry.
	- parameter queue: Optional dispatch queue to use when running the completion closure. Default value is main queue.
	- parameter completion: Closure to use for dictionary results.
	
	- returns: Returns a DBCommandToken that can be used to cancel the command before it executes. If the database file cannot be opened or table does not exist nil is returned.
	*/
	@discardableResult
	public func dictValueFromTable(_ table: DBTable, for key: String, queue: DispatchQueue? = nil, completion: @escaping (DictResults) -> Void) -> DBCommandToken? {
		let openResults = openDB()
		if case .failure(_) = openResults, !_tables.hasTable(table) {
			return nil
		}

		let (sql, columns) = dictValueForKeySQL(table: table, key: key, includeDates: false)

		let blockReference = _SQLiteCore.sqlSelect(sql, completion: { [weak self] (rowResults) -> Void in
			guard let self = self else { return }

			let dispatchQueue = queue ?? DispatchQueue.main
			dispatchQueue.async {
				let results: Result<[String: AnyObject], DBError>

				switch rowResults {
				case .success(let rows):
					guard let dictionaryValue = self.dictValueResults(table: table, key: key, results: rows, columns: columns)
						else {
						results = .failure(.other(0))
						completion(results)
						return
					}

					results = .success(dictionaryValue)

				case .failure(let error):
					results = .failure(error)
				}

				completion(results)
			}
		})

		return DBCommandToken(database: self, identifier: blockReference)
	}

	// MARK: - Delete
	/**
	Delete the value from the given table for the given key.
	
	- parameter table: The table to return keys from.
	- parameter key: The key for the entry.
	
	- returns: Bool Value was successfuly removed.
	*/
	@available( *, deprecated, renamed: "deleteFromTable")
	public func deleteForKey(table: String, key: String) -> Bool {
		assert(key != "", "key must be provided")

		return deleteForKey(table: DBTable(name: table), key: key, autoDelete: false, sourceDB: _instanceKey, originalDB: _instanceKey)
	}

	/**
	Delete the value from the given table for the given key.
	
	- parameter table: The table to return keys from.
	- parameter key: The key for the entry.
	
	- returns: Bool Value was successfuly removed.
	*/
	@discardableResult
	public func deleteFromTable(_ table: DBTable, for key: String) -> Bool {
		assert(key != "", "key must be provided")

		return deleteForKey(table: table, key: key, autoDelete: false, sourceDB: _instanceKey, originalDB: _instanceKey)
	}

	/**
	Removes the given table and associated values.
	
	- parameter table: The table to return keys from.
	
	- returns: Bool Table was successfuly removed.
	*/
	@discardableResult
	public func dropTable(_ table: DBTable) -> Bool {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return false
		}

		if !sqlExecute("drop table \(table)")
		|| !sqlExecute("drop table \(table)_arrayValues")
		|| !sqlExecute("delete from __tableArrayColumns where tableName = '\(table)'") {
			return false
		}

		_tables.dropTable(table)

		if _syncingEnabled && _unsyncedTables.doesNotContain(table.name) {
			let now = ALBNoSQLDB.stringValueForDate(Date())
			if !sqlExecute("insert into __synclog(timestamp, sourceDB, originalDB, tableName, activity, key) values('\(now)','\(_instanceKey)','\(_instanceKey)','\(table)','X',NULL)") {
				return false
			}

			let lastID = lastInsertID()

			if !sqlExecute("delete from __synclog where tableName = '\(table)' and rowid < \(lastID)") {
				return false
			}
		}

		return true
	}

	/**
	Removes all tables and associated values.
	
	- returns: Bool Tables were successfuly removed.
	*/
	@discardableResult
	public func dropAllTables() -> Bool {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return false
		}

		var successful = true
		let tables = _tables.allTables()
		for table in tables {
			successful = dropTable(table)
			if !successful {
				return false
			}
		}

		_tables.dropAllTables()

		return true
	}

	// MARK: - Sync
	/**
	Current syncing status. Nil if the database could not be opened.
	*/
	public var isSyncingEnabled: Bool? {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return nil
		}

		return _syncingEnabled
	}

	/**
	Enables syncing. Once enabled, a log is created for all current values in the tables.
	
	- returns: Bool If syncing was successfully enabled.
	*/
	public func enableSyncing() -> Bool {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return false
		}

		if _syncingEnabled {
			return true
		}

		if !sqlExecute("create table __synclog(timestamp text, sourceDB text, originalDB text, tableName text, activity text, key text)") {
			return false
		}
		sqlExecute("create index __synclog_index on __synclog(tableName,key)")
		sqlExecute("create index __synclog_source on __synclog(sourceDB,originalDB)")
		sqlExecute("create table __unsyncedTables(tableName text)")

		let now = ALBNoSQLDB.stringValueForDate(Date())
		let tables = _tables.allTables()
		for table in tables {
			if !sqlExecute("insert into __synclog(timestamp, sourceDB, originalDB, tableName, activity, key) select '\(now)','\(_instanceKey)','\(_instanceKey)','\(table.name)','U',key from \(table.name)") {
				return false
			}
		}

		_syncingEnabled = true
		return true
	}

	/**
	Disables syncing.
	
	- returns: Bool If syncing was successfully disabled.
	*/
	public func disableSyncing() -> Bool {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return false
		}

		if !_syncingEnabled {
			return true
		}

		if !sqlExecute("drop table __synclog") || !sqlExecute("drop table __unsyncedTables") {
			return false
		}

		_syncingEnabled = false

		return true
	}

	/**
	Read-only array of unsynced tables.  Any tables not in this array will be synced.
	*/
	var unsyncedTables: [String] {
		return _unsyncedTables
	}

	/**
	Sets the tables that are not to be synced.
	
	- parameter tables: Array of tables that are not to be synced.
	
	- returns: Bool If list was set successfully.
	*/
	public func setUnsyncedTables(_ tables: [String]) -> Bool {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return false
		}

		if !_syncingEnabled {
			print("syncing must be enabled before setting unsynced tables")
			return false
		}

		_unsyncedTables = [String]()
		for tableName in tables {
			sqlExecute("delete from __synclog where tableName = '\(tableName)'")
			_unsyncedTables.append(tableName)
		}

		return true
	}

	/**
	Creates a sync file that can be used on another ALBNoSQLDB instance to sync data. This is a synchronous call.
	
	- parameter filePath: The full path, including the file itself, to be used for the log file.
	- parameter lastSequence: The last sequence used for the given target  Initial sequence is 0.
	- parameter targetDBInstanceKey: The dbInstanceKey of the target database. Use the dbInstanceKey method to get the DB's instanceKey.
	
	- returns: (Bool,Int) If the file was successfully created and the lastSequence that should be used in subsequent calls to this instance for the given targetDBInstanceKey.
	*/
	public func createSyncFileAtURL(_ localURL: URL!, lastSequence: Int, targetDBInstanceKey: String) -> (Bool, Int) {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return (false, lastSequence)
		}

		if !_syncingEnabled {
			print("syncing must be enabled before creating sync file")
			return (false, lastSequence)
		}

		let filePath = localURL.path

		if FileManager.default.fileExists(atPath: filePath) {
			do {
				try FileManager.default.removeItem(atPath: filePath)
			} catch _ as NSError {
				return (false, lastSequence)
			}
		}

		FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)

		if let fileHandle = FileHandle(forWritingAtPath: filePath) {
			if let results = sqlSelect("select rowid,timestamp,originalDB,tableName,activity,key from __synclog where rowid > \(lastSequence) and sourceDB <> '\(targetDBInstanceKey)' and originalDB <> '\(targetDBInstanceKey)' order by rowid") {
				var lastRowID = lastSequence
				fileHandle.write("{\"sourceDB\":\"\(_instanceKey)\",\"logEntries\":[\n".dataValue())
				var firstEntry = true
				for row in results {
					lastRowID = row.values[0] as! Int
					let timeStamp = row.values[1] as! String
					let originalDB = row.values[2] as! String
					let tableName = row.values[3] as! String
					let activity = row.values[4] as! String
					let key = row.values[5] as! String?

					var entryDict = [String: AnyObject]()
					entryDict["timeStamp"] = timeStamp as AnyObject
					if originalDB != _instanceKey {
						entryDict["originalDB"] = originalDB as AnyObject
					}
					entryDict["tableName"] = tableName as AnyObject
					entryDict["activity"] = activity as AnyObject
					if let key = key {
						entryDict["key"] = key as AnyObject
						if activity == "U" {
							guard let dictValue = dictValueFromTable(DBTable(name: tableName), for: key, includeDates: true) else { continue }
							entryDict["value"] = dictValue as AnyObject
						}
					}

					let dataValue = try? JSONSerialization.data(withJSONObject: entryDict, options: JSONSerialization.WritingOptions(rawValue: 0))
					if firstEntry {
						firstEntry = false
					} else {
						fileHandle.write("\n,".dataValue())
					}

					fileHandle.write(dataValue!)
				}

				fileHandle.write("\n],\"lastSequence\":\(lastRowID)}".dataValue())
				fileHandle.closeFile()
				return (true, lastRowID)
			} else {
				do {
					try FileManager.default.removeItem(atPath: filePath)
				} catch _ {
					return (false, lastSequence)
				}
			}
		}

		return (false, lastSequence)
	}


	/**
	Processes a sync file created by another instance of ALBNoSQL This is a synchronous call.
	
	- parameter filePath: The path to the sync file.
	- parameter syncProgress: Optional function that will be called periodically giving the percent complete.
	
	- returns: (Bool,String,Int)  If the sync file was successfully processed,the instanceKey of the submiting DB, and the lastSequence that should be used in subsequent calls to the createSyncFile method of the instance that was used to create this file. If the database couldn't be opened or syncing hasn't been enabled, then the instanceKey will be empty and the lastSequence will be equal to zero.
	*/
	public typealias syncProgressUpdate = (_ percentComplete: Double) -> Void
	public func processSyncFileAtURL(_ localURL: URL!, syncProgress: syncProgressUpdate?) -> (Bool, String, Int) {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return (false, "", 0)
		}

		if !_syncingEnabled {
			print("syncing must be enabled before creating sync file")
			return (false, "", 0)
		}

		autoDelete()

		let filePath = localURL.path

		if let _ = FileHandle(forReadingAtPath: filePath) {
			// TODO: Stream in the file and parse as needed instead of parsing the entire thing at once to save on memory use
			let now = ALBNoSQLDB.stringValueForDate(Date())
			if let fileText = try? String(contentsOfFile: filePath, encoding: String.Encoding.utf8) {
				let dataValue = fileText.dataValue()

				if let objectValues = (try? JSONSerialization.jsonObject(with: dataValue, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: AnyObject] {
					let sourceDB = objectValues["sourceDB"] as! String
					let logEntries = objectValues["logEntries"] as! [[String: AnyObject]]
					let lastSequence = objectValues["lastSequence"] as! Int
					var index = 0
					for entry in logEntries {
						index += 1
						if index % 20 == 0 {
							if let syncProgress = syncProgress {
								let percent = (Double(index) / Double(logEntries.count))
								syncProgress(percent)
							}
						}

						let activity = entry["activity"] as! String
						let timeStamp = entry["timeStamp"] as! String
						let tableName = entry["tableName"] as! String
						let originalDB = (entry["originalDB"] == nil ? sourceDB : entry["originalDB"] as! String)

						// for entry activity U,D only process log entry if no local entry for same table/key that is greater than one received
						if activity == "D" || activity == "U" {
							if let key = entry["key"] as? String, let results = sqlSelect("select 1 from __synclog where tableName = '\(tableName)' and key = '\(key)' and timestamp > '\(timeStamp)'") {
								if results.isEmpty {
									if activity == "U" {
										// strip out the dates to send separately
										var objectValues = entry["value"] as! [String: AnyObject]
										let addedDateTime = objectValues["addedDateTime"] as! String
										let updatedDateTime = objectValues["updatedDateTime"] as! String
										let deleteDateTime = (objectValues["deleteDateTime"] == nil ? "NULL" : objectValues["deleteDateTime"] as! String)
										objectValues.removeValue(forKey: "addedDateTime")
										objectValues.removeValue(forKey: "updatedDateTime")
										objectValues.removeValue(forKey: "deleteDateTime")

										_ = setValue(table: DBTable(name: tableName), key: key, objectValues: objectValues, addedDateTime: addedDateTime, updatedDateTime: updatedDateTime, deleteDateTime: deleteDateTime, sourceDB: sourceDB, originalDB: originalDB)
									} else {
										_ = deleteForKey(table: DBTable(name: tableName), key: key, autoDelete: false, sourceDB: sourceDB, originalDB: originalDB)
									}
								}
							}
						} else {
							// for table activity X, delete any entries that occured BEFORE this event
							sqlExecute("delete from \(tableName) where key in (select key from __synclog where tableName = '\(tableName)' and timeStamp < '\(timeStamp)')")
							sqlExecute("delete from \(tableName)_arrayValues where key in (select key from __synclog where tableName = '\(tableName)' and timeStamp < '\(timeStamp)')")
							sqlExecute("delete from __synclog where tableName = '\(tableName)' and timeStamp < '\(timeStamp)'")
							sqlExecute("insert into __synclog(timestamp, sourceDB, originalDB, tableName, activity, key) values('\(now)','\(sourceDB)','\(originalDB)','\(tableName)','X',NULL)")
						}
					}

					return (true, sourceDB, lastSequence)
				} else {
					return (false, "", 0)
				}
			} else {
				return (false, "", 0)
			}
		}

		return (false, "", 0)
	}

	// MARK: - Misc
	/**
	The instanceKey for this database instance. Each ALBNoSQLDB database is created with a unique instanceKey. Is nil when database could not be opened.
	*/
	public var instanceKey: String? {
		let openResults = openDB()
		if case .success(_) = openResults {
			return _instanceKey
		}

		return nil
	}

	/**
	Replace single quotes with two single quotes for use in SQL commands.
	
	- returns: An escaped string.
	*/
	public func esc(_ source: String) -> String {
		return source.replacingOccurrences(of: "'", with: "''")
	}

	/**
	String value for a given date.
	
	- parameter date: Date to get string value of
	
	- returns: String Date presented as a string
	*/
	public class func stringValueForDate(_ date: Date) -> String {
		return ALBNoSQLDB.dateFormatter.string(from: date)
	}

	/**
	Date value for given string
	
	- parameter stringValue: String representation of date given in ISO format "yyyy-MM-dd'T'HH:mm:ss'.'SSSZZZZZ"
	
	- returns: NSDate? Date value. Is nil if the string could not be converted to date.
	*/
	public class func dateValueForString(_ stringValue: String) -> Date? {
		return ALBNoSQLDB.dateFormatter.date(from: stringValue)
	}

	// MARK: - Internal Initialization Methods
	private func openDB() -> BoolResults {
		if _SQLiteCore.isOpen {
			return BoolResults.success(true)
		}

		let dbFilePath: String

		if let _dbFileLocation = self._dbFileLocation {
			dbFilePath = _dbFileLocation.path
		} else {
			dbFilePath = defaultFileLocation()
			_dbFileLocation = URL(fileURLWithPath: dbFilePath)
		}

		var fileExists = false

		var openResults: BoolResults = .success(true)
		var previouslyOpened = false

		_dbQueue.sync { [weak self]() -> Void in
			guard let self = self else { return }

			self._SQLiteCore.openDBFile(dbFilePath, autoCloseTimeout: self.autoCloseTimeout) { (results, alreadyOpen, alreadyExists) -> Void in
				openResults = results
				previouslyOpened = alreadyOpen
				fileExists = alreadyExists

				self._lock.signal()
			}
			self._lock.wait()
		}

		if case .success(_) = openResults, !previouslyOpened {
			// if this fails, then the DB file has issues and should not be used
			if !sqlExecute("ANALYZE") {
				return BoolResults.failure(.damagedFile)
			}

			if !fileExists {
				makeDB()
			}

			checkSchema()
			_autoDeleteTimer.resume()
		}

		return openResults
	}

	private func defaultFileLocation() -> String {
		let searchPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
		let documentFolderPath = searchPaths[0]
		let dbFilePath = documentFolderPath + "/ABNoSQLDB.db"
		return dbFilePath
	}

	private func makeDB() {
		assert(sqlExecute("create table __settings(key text, value text)"), "Unable to make DB")
		assert(sqlExecute("insert into __settings(key,value) values('schema',1)"), "Unable to make DB")
		assert(sqlExecute("create table __tableArrayColumns(tableName text, arrayColumns text)"), "Unable to make DB")
	}

	private func checkSchema() {
		_tables.dropAllTables()
		let tableList = sqlSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
		if let tableList = tableList {
			for tableRow in tableList {
				let table = tableRow.values[0] as! String
				if !ALBNoSQLDB.reservedTable(table) && !table.hasSuffix("_arrayValues") {
					_tables.addTable(DBTable(name: table))
				}

				if table == "__synclog" {
					_syncingEnabled = true
				}
			}
		}

		if _syncingEnabled {
			_unsyncedTables = [String]()
			let unsyncedTables = sqlSelect("select tableName from __unsyncedTables")
			if let unsyncedTables = unsyncedTables {
				_unsyncedTables = unsyncedTables.map({ $0.values[0] as! String })
			}
		}

		if let keyResults = sqlSelect("select value from __settings where key = 'dbInstanceKey'") {
			if keyResults.isEmpty {
				_instanceKey = UUID().uuidString
				let parts = _instanceKey.components(separatedBy: "-")
				_instanceKey = parts[parts.count - 1]
				sqlExecute("insert into __settings(key,value) values('dbInstanceKey','\(_instanceKey)')")
			} else {
				_instanceKey = keyResults[0].values[0] as! String
			}
		}

		if let schemaResults = sqlSelect("select value from __settings where key = 'schema'") {
			var schemaVersion = Int((schemaResults[0].values[0] as! String))!
			if schemaVersion == 1 {
				sqlExecute("update __settings set value = 2 where key = 'schema'")
				schemaVersion = 2
			}

			// use this space to update the schema value in __settings and to update any other tables that need updating with the new schema
		}
	}
}

// MARK: - Internal data handling methods
extension ALBNoSQLDB {
	fileprivate func keysInTableSQL(table: DBTable, sortOrder: String?, conditions: [DBCondition]?, validateObjecs: Bool) -> String? {
		var arrayColumns = [String]()
		if let results = sqlSelect("select arrayColumns from __tableArrayColumns where tableName = '\(table)'") {
			if results.isNotEmpty {
				arrayColumns = (results[0].values[0] as! String).split { $0 == "," }.map { String($0) }
			}
		} else {
			return nil
		}

		let tableColumns = columnsInTable(table).map({ $0.name }) + ["key"]
		var selectClause = "select distinct a.key from \(table) a"
		var whereClause = " where 1=1"

		// if we have the include operator on an array object, do a left outer join
		if var conditionSet = conditions, let firstCondition = conditionSet.first {
			if validateObjecs {
				let invalidSets = conditionSet.filter({ !tableColumns.contains($0.objectKey) }).compactMap({ $0.set })
				let validConditions = conditionSet.filter({ !invalidSets.contains($0.set) })
				conditionSet = validConditions
			}
			
			for condition in conditionSet {
				if condition.conditionOperator == .contains && arrayColumns.filter({ $0 == condition.objectKey }).count == 1 {
					selectClause += " left outer join \(table)_arrayValues b on a.key = b.key"
					break
				}
			}

			whereClause += " AND ("
			// order the conditions array by page
			conditionSet.sort { $0.set < $1.set }

			// conditionDict: ObjectKey,operator,value
			var currentSet = firstCondition.set
			var inPage = true
			var inMultiPage = false
			var firstConditionInSet = true
			let hasMultipleSets = conditionSet.filter({ $0.set != firstCondition.set }).isNotEmpty

			for condition in conditionSet {
				if tableColumns.filter({ $0 == condition.objectKey }).isEmpty && arrayColumns.filter({ $0 == condition.objectKey }).isEmpty {
					if isDebugging {
						print("table \(table) has no column named \(condition.objectKey)")
					}
					return nil
				}

				let valueType = SQLiteCore.typeOfValue(condition.value)

				if currentSet != condition.set {
					currentSet = condition.set
					whereClause += ")"
					if inMultiPage {
						inMultiPage = false
						whereClause += ")"
					}
					whereClause += " OR ("

					inMultiPage = false
				} else {
					inPage = true
					if firstConditionInSet {
						firstConditionInSet = false
						if hasMultipleSets {
							whereClause += " ("
						}
					} else {
						if inMultiPage {
							whereClause += ")"
						}

						whereClause += " and key in (select key from \(table) where"
						inMultiPage = true
					}
				}

				switch condition.conditionOperator {
				case .contains:
					if arrayColumns.contains(condition.objectKey) {
						switch valueType {
						case .text:
							whereClause += "b.objectKey = '\(condition.objectKey)' and b.stringValue = '\(esc(condition.value as! String))'"
						case .int:
							whereClause += "b.objectKey = '\(condition.objectKey)' and b.intValue = \(condition.value)"
						case .double:
							whereClause += "b.objectKey = '\(condition.objectKey)' and b.doubleValue = \(condition.value)"
						default:
							break
						}
					} else {
						whereClause += " \(condition.objectKey) like '%%\(esc(condition.value as! String))%%'"
					}
				case .inList:
					whereClause += " \(condition.objectKey)  in ("
					if let stringArray = condition.value as? [String] {
						for value in stringArray {
							whereClause += "'\(esc(value))'"
						}
						whereClause += ")"
					} else {
						if let intArray = condition.value as? [Int] {
							for value in intArray {
								whereClause += "\(value)"
							}
							whereClause += ")"
						} else {
							for value in condition.value as! [Double] {
								whereClause += "\(value)"
							}
							whereClause += ")"
						}
					}

				default:
					if let conditionValue = condition.value as? String {
						whereClause += " \(condition.objectKey) \(condition.conditionOperator.rawValue) '\(esc(conditionValue))'"
					} else {
						whereClause += " \(condition.objectKey) \(condition.conditionOperator.rawValue) \(condition.value)"
					}
				}
			}

			whereClause += ")"

			if inMultiPage {
				whereClause += ")"
			}

			if inPage && hasMultipleSets {
				whereClause += ")"
				inPage = false
			}
		}

		if let sortOrder = sortOrder {
			whereClause += " order by \(sortOrder)"
		}

		let sql = selectClause + whereClause
		return sql
	}

	private func setValue(table: DBTable, key: String, objectValues: [String: AnyObject], addedDateTime: String, updatedDateTime: String, deleteDateTime: String, sourceDB: String, originalDB: String) -> Bool {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return false
		}

		if !createTable(table) {
			return false
		}

		// look for any array objects
		var arrayKeys = [String]()
		var arrayKeyTypes = [String]()
		var arrayTypes = [ValueType]()
		var arrayValues = [AnyObject]()

		for (objectKey, objectValue) in objectValues {
			let valueType = SQLiteCore.typeOfValue(objectValue)
			if [.textArray, .intArray, .doubleArray].contains(valueType) {
				arrayKeys.append(objectKey)
				arrayTypes.append(valueType)
				arrayKeyTypes.append("\(objectKey):\(valueType.rawValue)")
				arrayValues.append(objectValue)
			}
		}

		let joinedArrayKeys = arrayKeyTypes.joined(separator: ",")

		var sql = "select key from \(esc(table.name)) where key = '\(esc(key))'"

		var tableHasKey = false
		guard let results = sqlSelect(sql) else { return false }

		if results.isEmpty {
			// key doesn't exist, insert values
			sql = "insert into \(table) (key,addedDateTime,updatedDateTime,autoDeleteDateTime,hasArrayValues"
			var placeHolders = "'\(key)','\(addedDateTime)','\(updatedDateTime)',\(deleteDateTime),'\(joinedArrayKeys)'"

			for (objectKey, objectValue) in objectValues {
				if objectKey == "key" {
					continue
				}
				
				let valueType = SQLiteCore.typeOfValue(objectValue)
				if [.int, .double, .text, .bool].contains(valueType) {
					sql += ",\(objectKey)"
					placeHolders += ",?"
				}
			}

			sql += ") values(\(placeHolders))"
		} else {
			tableHasKey = true
			sql = "update \(table) set updatedDateTime='\(updatedDateTime)',autoDeleteDateTime=\(deleteDateTime),hasArrayValues='\(joinedArrayKeys)'"
			for (objectKey, objectValue) in objectValues {
				if objectKey == "key" {
					continue
				}
				
				let valueType = SQLiteCore.typeOfValue(objectValue)
				if [.int, .double, .text, .bool].contains(valueType) {
					sql += ",\(objectKey)=?"
				}
			}
			// set unused columns to NULL
			let objectKeys = objectValues.keys
			let columns = columnsInTable(table)
			for column in columns {
				let filteredKeys = objectKeys.filter({ $0 == column.name })
				if filteredKeys.isEmpty {
					sql += ",\(column.name)=NULL"
				}
			}
			sql += " where key = '\(key)'"
		}

		if !setTableValues(objectValues: objectValues, sql: sql) {
			// adjust table columns
			validateTableColumns(table: table, objectValues: objectValues as [String: AnyObject])
			// try again
			if !setTableValues(objectValues: objectValues, sql: sql) {
				return false
			}
		}

		// process any array values
		for index in 0 ..< arrayKeys.count {
			if !setArrayValues(table: table, arrayValues: arrayValues[index] as! [AnyObject], valueType: arrayTypes[index], key: key, objectKey: arrayKeys[index]) {
				return false
			}
		}

		if _syncingEnabled && _unsyncedTables.doesNotContain(table.name) {
			let now = ALBNoSQLDB.stringValueForDate(Date())
			sql = "insert into __synclog(timestamp, sourceDB, originalDB, tableName, activity, key) values('\(now)','\(sourceDB)','\(originalDB)','\(table)','U','\(esc(key))')"

			// TODO: Rework this so if the synclog stuff fails we do a rollback and return false
			if sqlExecute(sql) {
				let lastID = self.lastInsertID()

				if tableHasKey {
					sql = "delete from __synclog where tableName = '\(table)' and key = '\(self.esc(key))' and rowid < \(lastID)"
					self.sqlExecute(sql)
				}
			}
		}

		return true
	}

	private func setTableValues(objectValues: [String: AnyObject], sql: String) -> Bool {
		var successful = false

		_dbQueue.sync { [weak self]() -> Void in
			guard let self = self else { return }

			self._SQLiteCore.setTableValues(objectValues: objectValues, sql: sql, completion: { (success) -> Void in
				successful = success
				self._lock.signal()
			})
			self._lock.wait()
		}

		return successful
	}

	private func setArrayValues(table: DBTable, arrayValues: [AnyObject], valueType: ValueType, key: String, objectKey: String) -> Bool {
		var successful = sqlExecute("delete from \(table)_arrayValues where key='\(key)' and objectKey='\(objectKey)'")
		if !successful {
			return false
		}

		for value in arrayValues {
			switch valueType {
			case .textArray:
				successful = sqlExecute("insert into \(table)_arrayValues(key,objectKey,stringValue) values('\(key)','\(objectKey)','\(esc(value as! String))')")
			case .intArray:
				successful = sqlExecute("insert into \(table)_arrayValues(key,objectKey,intValue) values('\(key)','\(objectKey)',\(value as! Int))")
			case .doubleArray:
				successful = sqlExecute("insert into \(table)_arrayValues(key,objectKey,doubleValue) values('\(key)','\(objectKey)',\(value as! Double))")
			default:
				successful = true
			}

			if !successful {
				return false
			}
		}

		return true
	}

	private func deleteForKey(table: DBTable, key: String, autoDelete: Bool, sourceDB: String, originalDB: String) -> Bool {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return false
		}

		if !_tables.hasTable(table) {
			return false
		}

		if !sqlExecute("delete from \(table) where key = '\(esc(key))'") || !sqlExecute("delete from \(table)_arrayValues where key = '\(esc(key))'") {
			return false
		}

		let now = ALBNoSQLDB.stringValueForDate(Date())
		if _syncingEnabled && _unsyncedTables.doesNotContain(table.name) {
			var sql = ""
			// auto-deleted entries will be automatically removed from any other databases too. Don't need to log this deletion.
			if !autoDelete {
				sql = "insert into __synclog(timestamp, sourceDB, originalDB, tableName, activity, key) values('\(now)','\(sourceDB)','\(originalDB)','\(table)','D','\(esc(key))')"
				_ = sqlExecute(sql)

				let lastID = lastInsertID()
				sql = "delete from __synclog where tableName = '\(table)' and key = '\(esc(key))' and rowid < \(lastID)"
				_ = sqlExecute(sql)
			} else {
				sql = "delete from __synclog where tableName = '\(table)' and key = '\(esc(key))'"
				_ = sqlExecute(sql)
			}
		}

		return true
	}

	private func autoDelete() {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return
		}

		let now = ALBNoSQLDB.stringValueForDate(Date())
		let tables = _tables.allTables()
		for table in tables {
			if !ALBNoSQLDB.reservedTable(table.name) {
				let sql = "select key from \(table) where autoDeleteDateTime < '\(now)'"
				if let results = sqlSelect(sql) {
					for row in results {
						let key = row.values[0] as! String
						_ = deleteForKey(table: table, key: key, autoDelete: true, sourceDB: _instanceKey, originalDB: _instanceKey)
					}
				}
			}
		}
	}

	private func dictValueFromTable(_ table: DBTable, for key: String, includeDates: Bool) -> [String: AnyObject]? {
		assert(key != "", "key value must be provided")
		let openResults = openDB()
		if case .failure(_) = openResults, !_tables.hasTable(table) {
			return nil
		}

		let (sql, columns) = dictValueForKeySQL(table: table, key: key, includeDates: includeDates)
		let results = sqlSelect(sql)

		return dictValueResults(table: table, key: key, results: results, columns: columns)
	}

	private func dictValueResults(table: DBTable, key: String, results: [DBRow]?, columns: [TableColumn]) -> [String: AnyObject]? {
		guard var results = results, results.isNotEmpty else { return nil }

		var valueDict = [String: AnyObject]()
		for (columnIndex, column) in columns.enumerated() {
			let valueIndex = columnIndex + 1
			if results[0].values[valueIndex] != nil {
				if column.type == .bool, let intValue = results[0].values[valueIndex] as? Int {
					valueDict[column.name] = (intValue == 0 ? false : true) as AnyObject
				} else {
					valueDict[column.name] = results[0].values[valueIndex]
				}
			}
		}

		// handle any arrayValues
		let arrayObjects = (results[0].values[0] as! String).split { $0 == "," }.map { String($0) }
		for object in arrayObjects {
			if object == "" {
				continue
			}

			let keyType = object.split { $0 == ":" }.map { String($0) }
			let objectKey = keyType[0]
			let valueType = ValueType(rawValue: keyType[1] as String)!
			var stringArray = [String]()
			var intArray = [Int]()
			var doubleArray = [Double]()

			var arrayQueryResults: [DBRow]?
			switch valueType {
			case .textArray:
				arrayQueryResults = sqlSelect("select stringValue from \(table)_arrayValues where key = '\(key)' and objectKey = '\(objectKey)'")
			case .intArray:
				arrayQueryResults = sqlSelect("select intValue from \(table)_arrayValues where key = '\(key)' and objectKey = '\(objectKey)'")
			case .doubleArray:
				arrayQueryResults = sqlSelect("select doubleValue from \(table)_arrayValues where key = '\(key)' and objectKey = '\(objectKey)'")
				valueDict[objectKey] = doubleArray as AnyObject
			default:
				break
			}

			guard let arrayResults = arrayQueryResults else { return nil }

			for index in 0 ..< arrayResults.count {
				switch valueType {
				case .textArray:
					stringArray.append(arrayResults[index].values[0] as! String)
				case .intArray:
					intArray.append(arrayResults[index].values[0] as! Int)
				case .doubleArray:
					doubleArray.append(arrayResults[index].values[0] as! Double)
				default:
					break
				}
			}

			switch valueType {
			case .textArray:
				valueDict[objectKey] = stringArray as AnyObject
			case .intArray:
				valueDict[objectKey] = intArray as AnyObject
			case .doubleArray:
				valueDict[objectKey] = doubleArray as AnyObject
			default:
				break
			}
		}

		return valueDict
	}

	private func dictValueForKeySQL(table: DBTable, key: String, includeDates: Bool) -> (String, [TableColumn]) {
		var columns = columnsInTable(table)
		if includeDates {
			columns.append(TableColumn(name: "autoDeleteDateTime", type: .text))
			columns.append(TableColumn(name: "addedDateTime", type: .text))
			columns.append(TableColumn(name: "updatedDateTime", type: .text))
		}

		var sql = "select hasArrayValues"
		for column in columns {
			sql += ",\(column.name)"
		}
		sql += " from \(table) where key = '\(esc(key))'"

		return (sql, columns)
	}

	// MARK: - Internal Table methods
	struct TableColumn {
		fileprivate var name: String
		fileprivate var type: ValueType

		fileprivate init(name: String, type: ValueType) {
			self.name = name
			self.type = type
		}
	}

	fileprivate static func reservedTable(_ table: String) -> Bool {
		return table.hasPrefix("__") || table.hasPrefix("sqlite_stat")
	}

	private func reservedColumn(_ column: String) -> Bool {
		return column == "key"
		|| column == "addedDateTime"
		|| column == "updatedDateTime"
		|| column == "autoDeleteDateTime"
		|| column == "hasArrayValues"
		|| column == "arrayValues"
	}

	private func createTable(_ table: DBTable) -> Bool {
		if _tables.hasTable(table) {
			return true
		}

		if !sqlExecute("create table \(table) (key text PRIMARY KEY, autoDeleteDateTime text, addedDateTime text, updatedDateTime text, hasArrayValues text)") || !sqlExecute("create index idx_\(table)_autoDeleteDateTime on \(table)(autoDeleteDateTime)") {
			return false
		}

		if !sqlExecute("create table \(table)_arrayValues (key text, objectKey text, stringValue text, intValue int, doubleValue double)") || !sqlExecute("create index idx_\(table)_arrayValues_keys on \(table)_arrayValues(key,objectKey)") {
			return false
		}

		_tables.addTable(table)

		return true
	}

	private func createIndexesForTable(_ table: DBTable) {
		if !_tables.hasTable(table) {
			return
		}

		if let indexes = _indexes[table.name] {
			for index in indexes {
				var indexName = index.replacingOccurrences(of: ",", with: "_")
				indexName = "idx_\(table)_\(indexName)"

				var sql = "select * from sqlite_master where tbl_name = '\(table)' and name = '\(indexName)'"
				if let results = sqlSelect(sql), results.isEmpty {
					sql = "CREATE INDEX \(indexName) on \(table)(\(index))"
					_ = sqlExecute(sql)
				}
			}
		}
	}

	private func columnsInTable(_ table: DBTable) -> [TableColumn] {
		guard let tableInfo = sqlSelect("pragma table_info(\(table))") else { return [] }
		var columns = [TableColumn]()
		for info in tableInfo {
			let columnName = info.values[1] as! String
			if !reservedColumn(columnName) {
				let rawValue = info.values[2] as! String
				let valueType = ValueType.fromRaw(rawValue)
				columns.append(TableColumn(name: columnName, type: valueType))
			}
		}

		return columns
	}

	private func validateTableColumns(table: DBTable, objectValues: [String: AnyObject]) {
		let columns = columnsInTable(table)
		// determine missing columns and add them
		for (objectKey, value) in objectValues {
			if objectKey == "key" {
				continue
			}
			
			assert(!reservedColumn(objectKey as String), "Reserved column")
			assert((objectKey as String).range(of: "'") == nil, "Single quote not allowed in column names")

			let found = columns.filter({ $0.name == objectKey }).isNotEmpty

			if !found {
				let valueType = SQLiteCore.typeOfValue(value)
				assert(valueType != .unknown, "column types are int, double, string, bool or arrays of int, double, or string")

				if valueType == .null {
					continue
				}

				if [.int, .double, .text].contains(valueType) {
					let sql = "alter table \(table) add column \(objectKey) \(valueType.rawValue)"
					_ = sqlExecute(sql)
				} else if valueType == .bool {
					let sql = "alter table \(table) add column \(objectKey) int"
					_ = sqlExecute(sql)
				} else {
					// array type
					let sql = "select arrayColumns from __tableArrayColumns where tableName = '\(table)'"
					if let results = sqlSelect(sql) {
						var arrayColumns = ""
						if results.isNotEmpty {
							arrayColumns = results[0].values[0] as! String
							arrayColumns += ",\(objectKey)"
							_ = sqlExecute("delete from __tableArrayColumns where tableName = '\(table)'")
						} else {
							arrayColumns = objectKey as String
						}
						_ = sqlExecute("insert into __tableArrayColumns(tableName,arrayColumns) values('\(table)','\(arrayColumns)')")
					}
				}
			}
		}

		createIndexesForTable(table)
	}

	// MARK: - SQLite execute/query
	@discardableResult
	private func sqlExecute(_ sql: String) -> Bool {
		var successful = false

		_dbQueue.sync { [weak self]() -> Void in
			guard let self = self else { return }

			_ = self._SQLiteCore.sqlExecute(sql, completion: { (success) in
				successful = success
				self._lock.signal()
			})
			self._lock.wait()
		}

		return successful
	}

	private func lastInsertID() -> sqlite3_int64 {
		var lastID: sqlite3_int64 = 0

		_dbQueue.sync(execute: { [weak self]() -> Void in
			guard let self = self else { return }

			self._SQLiteCore.lastID({ (lastInsertionID) -> Void in
				lastID = lastInsertionID
				self._lock.signal()
			})
			self._lock.wait()
		})

		return lastID
	}

	public func sqlSelect(_ sql: String) -> [DBRow]? {
		var results: RowResults = .success([])

		let openResults = openDB()
		if case .failure(_) = openResults {
			return nil
		}

		_dbQueue.sync { [weak self]() -> Void in
			guard let self = self else { return }

			_ = self._SQLiteCore.sqlSelect(sql, completion: { (rowResults) -> Void in
				results = rowResults
				self._lock.signal()
			})
			self._lock.wait()
		}

		switch results {
		case .success(let rows):
			return rows

		case .failure(_):
			return nil
		}
	}

	public func sqlSelect(_ sql: String, queue: DispatchQueue? = nil, completion: @escaping (RowResults) -> Void) -> DBCommandToken? {
		let openResults = openDB()
		if case .failure(_) = openResults {
			return nil
		}

		let blockReference: UInt = self._SQLiteCore.sqlSelect(sql, completion: { (rowResults) -> Void in
			let dispatchQueue = queue ?? DispatchQueue.main
			dispatchQueue.async {
				let results: RowResults

				switch rowResults {
				case .success(let rows):
					results = .success(rows)

				case .failure(let error):
					results = .failure(error)
				}

				completion(results)
			}
		})

		return DBCommandToken(database: self, identifier: blockReference)
	}

	func dequeueCommand(_ commandReference: UInt) -> Bool {
		var removed = true

		_dbQueue.sync { [weak self]() -> Void in
			guard let self = self else { return }

			self._SQLiteCore.removeExecutionBlock(commandReference, completion: { (results) -> Void in
				removed = results
				self._lock.signal()
			})
			self._lock.wait()
		}

		return removed
	}
}

// MARK: - SQLiteCore
private extension ALBNoSQLDB {
	final class SQLiteCore: Thread {
		var isOpen = false
		var isDebugging = false

		private struct ExecutionBlock {
			var block: Any
			var blockReference: UInt
		}

		private var _sqliteDB: OpaquePointer?
		private var _threadLock = DispatchSemaphore(value: 0)
		private var _queuedBlocks = [ExecutionBlock]()
		private let _closeQueue = DispatchQueue(label: "com.AaronLBratcher.ALBNoSQLDBCloseQueue", attributes: [])
		private var _autoCloseTimer: RepeatingTimer?
		private var _dbFilePath = ""
		private var _autoCloseTimeout: TimeInterval = 0
		private var _lastActivity: Double = 0
		private var _automaticallyClosed = false
		private let _blockQueue = DispatchQueue(label: "com.AaronLBratcher.ALBNoSQLDBBlockQueue", attributes: [])
		private var _blockReference: UInt = 1

		private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

		class func typeOfValue(_ value: AnyObject) -> ValueType {
			let valueType: ValueType

			switch value {
			case is [String]:
				valueType = .textArray
			case is [Int]:
				valueType = .intArray
			case is [Double]:
				valueType = .doubleArray
			case is String:
				valueType = .text
			case is Int:
				valueType = .int
			case is Double:
				valueType = .double
			case is Bool:
				valueType = .bool
			case is NSNull:
				valueType = .null
			default:
				valueType = .unknown
			}

			return valueType
		}

		func openDBFile(_ dbFilePath: String, autoCloseTimeout: Int, completion: @escaping (_ successful: BoolResults, _ openedFromOtherThread: Bool, _ fileExists: Bool) -> Void) {
			_autoCloseTimeout = TimeInterval(exactly: autoCloseTimeout) ?? 0.0
			_dbFilePath = dbFilePath

			let block = { [unowned self] in
				let fileExists = FileManager.default.fileExists(atPath: dbFilePath)
				if self.isOpen {
					completion(BoolResults.success(true), true, fileExists)
					return
				}

				if autoCloseTimeout > 0 {
					self._autoCloseTimer = RepeatingTimer(timeInterval: self._autoCloseTimeout) {
						self.close(automatically: true)
					}
				}

				let openResults = self.openFile()
				switch openResults {
				case .success(_):
					self.isOpen = true
					completion(BoolResults.success(true), false, fileExists)

				case .failure(let error):
					self.isOpen = false
					completion(BoolResults.failure(error), false, fileExists)
				}

				return
			}

			_ = addBlock(block)
		}

		func close(automatically: Bool = false) {
			let block = { [unowned self] in
				if automatically {
					if self._automaticallyClosed || Date().timeIntervalSince1970 < (self._lastActivity + Double(self._autoCloseTimeout)) {
						return
					}

					self._autoCloseTimer?.suspend()
					self._automaticallyClosed = true
				} else {
					self.isOpen = false
				}

				sqlite3_close_v2(self._sqliteDB)
				self._sqliteDB = nil
			}

			_ = addBlock(block)
		}

		func lastID(_ completion: @escaping (_ lastInsertionID: sqlite3_int64) -> Void) {
			let block = { [unowned self] in
				completion(sqlite3_last_insert_rowid(self._sqliteDB))
			}

			_ = addBlock(block)
		}

		func sqlExecute(_ sql: String, completion: @escaping (_ success: Bool) -> Void) -> UInt {
			let block = { [unowned self] in
				var dbps: OpaquePointer?
				defer {
					if dbps != nil {
						sqlite3_finalize(dbps)
					}
				}

				var status = sqlite3_prepare_v2(self._sqliteDB, sql, -1, &dbps, nil)
				if status != SQLITE_OK {
					self.displaySQLError(sql)
					completion(false)
					return
				}

				status = sqlite3_step(dbps)
				if status != SQLITE_DONE && status != SQLITE_OK {
					self.displaySQLError(sql)
					completion(false)
					return
				}

				completion(true)
				return
			}

			return addBlock(block)
		}

		func sqlSelect(_ sql: String, completion: @escaping (_ results: RowResults) -> Void) -> UInt {
			let block = { [unowned self] in
				var rows = [DBRow]()
				var dbps: OpaquePointer?
				defer {
					if dbps != nil {
						sqlite3_finalize(dbps)
					}
				}

				var status = sqlite3_prepare_v2(self._sqliteDB, sql, -1, &dbps, nil)
				if status != SQLITE_OK {
					self.displaySQLError(sql)
					completion(RowResults.failure(DBError(rawValue: Int(status))))
					return
				}

				if self.isDebugging {
					self.explain(sql)
				}

				repeat {
					status = sqlite3_step(dbps)
					if status == SQLITE_ROW {
						var row = DBRow()
						let count = sqlite3_column_count(dbps)
						for index in 0 ..< count {
							let columnType = sqlite3_column_type(dbps, index)
							switch columnType {
							case SQLITE_TEXT:
								let value = String(cString: sqlite3_column_text(dbps, index))
								row.values.append(value as AnyObject)
							case SQLITE_INTEGER:
								row.values.append(Int(sqlite3_column_int64(dbps, index)) as AnyObject)
							case SQLITE_FLOAT:
								row.values.append(Double(sqlite3_column_double(dbps, index)) as AnyObject)
							default:
								row.values.append(nil)
							}
						}

						rows.append(row)
					}
				} while status == SQLITE_ROW

				if status != SQLITE_DONE {
					self.displaySQLError(sql)
					completion(RowResults.failure(DBError(rawValue: Int(status))))
					return
				}

				completion(RowResults.success(rows))
				return
			}

			return addBlock(block)
		}

		func removeExecutionBlock(_ blockReference: UInt, completion: @escaping (_ success: Bool) -> Void) {
			let block = {
				var blockArrayIndex: Int?
				for i in 0..<self._queuedBlocks.count {
					if self._queuedBlocks[i].blockReference == blockReference {
						blockArrayIndex = i
						break
					}
				}

				if let blockArrayIndex = blockArrayIndex {
					self._queuedBlocks.remove(at: blockArrayIndex)
					completion(true)
				} else {
					completion(false)
				}
			}

			_blockQueue.sync {
				if _blockReference > (UInt.max - 5) {
					_blockReference = 1
				} else {
					_blockReference += 1
				}

				let executionBlock = ExecutionBlock(block: block, blockReference: _blockReference)

				_queuedBlocks.insert(executionBlock, at: 0)
				_threadLock.signal()
			}

		}

		func setTableValues(objectValues: [String: AnyObject], sql: String, completion: @escaping (_ success: Bool) -> Void) {
			let block = { [unowned self] in
				var dbps: OpaquePointer?
				defer {
					if dbps != nil {
						sqlite3_finalize(dbps)
					}
				}

				var status = sqlite3_prepare_v2(self._sqliteDB, sql, -1, &dbps, nil)
				if status != SQLITE_OK {
					self.displaySQLError(sql)
					completion(false)
					return
				} else {
					// try to bind the object properties to table fields.
					var index: Int32 = 1

					for (objectKey, objectValue) in objectValues {
						if objectKey == "key" {
							continue
						}
						
						let valueType = SQLiteCore.typeOfValue(objectValue)
						guard [.int, .double, .text, .bool].contains(valueType) else { continue }

						let value: AnyObject
						if valueType == .bool, let boolValue = objectValue as? Bool {
							value = (boolValue ? 1 : 0) as AnyObject
						} else {
							value = objectValue
						}

						status = self.bindValue(dbps!, index: index, value: value)
						if status != SQLITE_OK {
							self.displaySQLError(sql)
							completion(false)
							return
						}

						index += 1
					}

					status = sqlite3_step(dbps)
					if status != SQLITE_DONE && status != SQLITE_OK {
						self.displaySQLError(sql)
						completion(false)
						return
					}
				}

				completion(true)
				return
			}

			_ = addBlock(block)
		}

		private func bindValue(_ statement: OpaquePointer, index: Int32, value: AnyObject) -> Int32 {
			var status = SQLITE_OK
			let valueType = SQLiteCore.typeOfValue(value)

			switch valueType {
			case .text:
				status = sqlite3_bind_text(statement, index, value as! String, -1, SQLITE_TRANSIENT)
			case .int:
				let int64Value = Int64(value as! Int)
				status = sqlite3_bind_int64(statement, index, int64Value)
			case .double:
				status = sqlite3_bind_double(statement, index, value as! Double)
			case .bool:
				status = sqlite3_bind_int(statement, index, Int32(value as! Int))
			default:
				status = SQLITE_OK
			}

			return status
		}

		private func displaySQLError(_ sql: String) {
			if !isDebugging { return }
			
			print("Error: \(dbErrorMessage)")
			print("     on command - \(sql)")
			print("")
		}

		private var dbErrorMessage: String {
			guard let message = UnsafePointer<Int8>(sqlite3_errmsg(_sqliteDB)) else { return "Unknown Error" }
			return String(cString: message)
		}

		private func explain(_ sql: String) {
			var dbps: OpaquePointer?
			let explainCommand = "EXPLAIN QUERY PLAN \(sql)"
			sqlite3_prepare_v2(_sqliteDB, explainCommand, -1, &dbps, nil)
			print("\n\n.  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  .  \nQuery:\(sql)\n\nAnalysis:\n")
			while (sqlite3_step(dbps) == SQLITE_ROW) {
				let iSelectid = sqlite3_column_int(dbps, 0)
				let iOrder = sqlite3_column_int(dbps, 1)
				let iFrom = sqlite3_column_int(dbps, 2)
				let value = String(cString: sqlite3_column_text(dbps, 3))

				print("\(iSelectid) \(iOrder) \(iFrom) \(value)\n=================================================\n\n")
			}

			sqlite3_finalize(dbps)
		}

		private func addBlock(_ block: Any) -> UInt {
			_blockQueue.sync {
				if _blockReference > (UInt.max - 5) {
					_blockReference = 1
				} else {
					_blockReference += 1
				}
			}

			_blockQueue.async {
				let executionBlock = ExecutionBlock(block: block, blockReference: self._blockReference)

				self._queuedBlocks.append(executionBlock)
				self._threadLock.signal()
			}

			return _blockReference
		}

		override func main() {
			while true {
				_autoCloseTimer?.suspend()

				if _automaticallyClosed {
					let results = openFile()
					if case .failure(_) = results {
						fatalError("Unable to open DB")
					}
				}

				while _queuedBlocks.isNotEmpty {
					if isDebugging {
						Thread.sleep(forTimeInterval: 0.1)
					}

					_blockQueue.sync {
						if let executionBlock = _queuedBlocks.first, let block = executionBlock.block as? () -> Void {
							_queuedBlocks.removeFirst()
							block()
						}
					}
				}

				_lastActivity = Date().timeIntervalSince1970
				_autoCloseTimer?.resume()

				_threadLock.wait()
			}
		}

		private func openFile() -> Result<Bool, DBError> {
			_sqliteDB = nil
			let status = sqlite3_open_v2(_dbFilePath.cString(using: .utf8)!, &self._sqliteDB, SQLITE_OPEN_FILEPROTECTION_COMPLETE | SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil)

			if status != SQLITE_OK {
				if isDebugging {
					print("Error opening SQLite Database: \(status)")
				}
				return BoolResults.failure(DBError(rawValue: Int(status)))
			}

			_autoCloseTimer?.resume()
			_automaticallyClosed = false
			return BoolResults.success(true)
		}
	}
}

// MARK: - String Extensions
private extension String {
	func dataValue() -> Data {
		return data(using: .utf8, allowLossyConversion: false)!
	}
}

private class RepeatingTimer {
	private enum State {
		case suspended
		case resumed
	}

	private let timeInterval: TimeInterval
	private let eventHandler: (() -> Void)
	private var state = State.suspended
	private lazy var timer: DispatchSourceTimer = makeTimer()

	init(timeInterval: TimeInterval = 60.0, eventHandler: @escaping (() -> Void)) {
		self.timeInterval = timeInterval
		self.eventHandler = eventHandler
	}

	private func makeTimer() -> DispatchSourceTimer {
		let timer = DispatchSource.makeTimerSource()
		timer.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
		timer.setEventHandler(handler: { [weak self] in
			self?.eventHandler()
		})
		return timer
	}

	deinit {
		timer.setEventHandler { }
		timer.cancel()
		resume()
	}

	func resume() {
		if state == .resumed { return }

		state = .resumed
		timer.resume()
	}

	func suspend() {
		if state == .suspended { return }

		state = .suspended
		timer.suspend()
	}
}

fileprivate extension Collection {
	var isNotEmpty: Bool {
		return !isEmpty
	}
}

fileprivate extension Array where Element: Equatable {
	func doesNotContain(_ element: Element) -> Bool {
		return !contains(element)
	}
}
