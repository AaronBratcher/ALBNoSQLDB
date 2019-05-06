//
//  DBObject.swift
//  ALBNoSQLDB
//
//  Created by Aaron Bratcher  on 4/25/19.
//  Copyright © 2019 Aaron Bratcher. All rights reserved.
//

import Foundation

public protocol DBObject: Codable {
	static var table: DBTable { get }
	var key: String { get set }
}

extension DBObject {
	/**
     Instantiate object and populate with values from the database. If instantiation fails, nil is returned.

     - parameter db: Database object holding the data.
     - parameter key: Key of the data entry.
	*/
	public init?(db: ALBNoSQLDB, key: String) {
		guard let dictionaryValue = db.dictValueFromTable(Self.table, for: key)
			, let dbObject: Self = Self.dbObjectWithDict(dictionaryValue, for: key)
			else { return nil }

		self = dbObject
	}

	/**
     Save the object to the database

     - parameter db: Database object to hold the data.
     - parameter expiration: Optional Date specifying when the data is to be automatically deleted. Default value is nil specifying no automatic deletion.

     - returns: Discardable Bool value of a successful save.
	*/
	@discardableResult
	public func save(to db: ALBNoSQLDB, autoDeleteAfter expiration: Date? = nil) -> Bool {
		guard let jsonValue = jsonValue
			, db.setValueInTable(Self.table, for: key, to: jsonValue, autoDeleteAfter: expiration)
			else { return false }

		return true
	}

	/**
     Asynchronously instantiate object and populate with values from the database before executing the passed block with object. If object could not be instantiated properly, block is not executed.
	
	 - parameter db: Database object to hold the data.
	 - parameter key: Key of the data entry.
	 - parameter queue: DispatchQueue to run the execution block on. Default value is nil specifying the main queue.
	 - parameter block: Block of code to execute with instantiated object.
	
	 - returns: DBCommandToken that can be used to cancel the call before it executes. Nil is returned if database could not be opened.
	*/
	public static func loadObjectFromDB<T: DBObject>(_ db: ALBNoSQLDB, for key: String, queue: DispatchQueue? = nil, completion: @escaping (T) -> Void) -> DBCommandToken? {
		let token = db.dictValueFromTable(T.table, for: key, queue: queue, completion: { (results) in
			if case .success(let dictionaryValue) = results
				, let dbObject: T = dbObjectWithDict(dictionaryValue, for: key) {
					completion(dbObject)
			}
		})

		return token
	}

	private static func dbObjectWithDict<T: DBObject>(_ dictionaryValue: [String: AnyObject], for key: String) -> T? {
		var dictionaryValue = dictionaryValue

		dictionaryValue["key"] = key as AnyObject
		let decoder = DictDecoder(dictionaryValue)
		return try? T(from: decoder)
	}

	/**
     JSON string value based on the what's saved in the encode method
     */
	public var jsonValue: String? {
		let jsonEncoder = JSONEncoder()
		jsonEncoder.dateEncodingStrategy = .formatted(ALBNoSQLDB.dateFormatter)

		do {
			let jsonData = try jsonEncoder.encode(self)
			let jsonString = String(data: jsonData, encoding: .utf8)
			return jsonString
		}

		catch _ {
			return nil
		}
	}
}

private enum DictDecoderError: Error {
	case missingValueForKey(String)
	case invalidDate(String)
	case invalidURL(String)
	case invalidUUID(String)
	case invalidJSON(String)
}

private extension Bool {
	init<T : Numeric>(_ number: T) {
		if number == 0 {
			self.init(false)
		} else {
			self.init(true)
		}
	}

	init(_ string: String) {
		self.init(string == "1" || string.uppercased() == "YES" || string.uppercased() == "TRUE")
	}
}

private class DictKeyedContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
	typealias Key = K

	let codingPath: Array<CodingKey> = []
	var allKeys: Array<K> { return dict.keys.compactMap { K(stringValue: $0) } }

	private var dict: [String: AnyObject]

	init(_ dict: [String: AnyObject]) {
		self.dict = dict
	}

	func contains(_ key: K) -> Bool {
		return dict[key.stringValue] != nil
	}

	func decodeNil(forKey key: K) throws -> Bool {
		if dict[key.stringValue] == nil {
			throw DictDecoderError.missingValueForKey(key.stringValue)
		}

		return false
	}

	func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
		guard let value = dict[key.stringValue] else {
			throw DictDecoderError.missingValueForKey(key.stringValue)
		}

		if let intValue = value as? Int {
			return Bool(intValue)
		}

		if let stringValue = value as? String {
			return Bool(stringValue)
		}

		throw DictDecoderError.missingValueForKey(key.stringValue)
	}

	func decode(_ type: Int.Type, forKey key: K) throws -> Int {
		guard let value = dict[key.stringValue] else {
			throw DictDecoderError.missingValueForKey(key.stringValue)
		}

		if let intValue = value as? Int {
			return intValue
		}

		guard let stringValue = value as? String
			, let intValue = Int(stringValue)
			else {
			throw DictDecoderError.missingValueForKey(key.stringValue)
		}

		return intValue
	}

	func decode(_ type: Double.Type, forKey key: K) throws -> Double {
		guard let value = dict[key.stringValue] else {
			throw DictDecoderError.missingValueForKey(key.stringValue)
		}

		if let doubleValue = value as? Double {
			return doubleValue
		}

		guard let stringValue = value as? String
			, let doubleValue = Double(stringValue)
			else {
			throw DictDecoderError.missingValueForKey(key.stringValue)
		}

		return doubleValue
	}

	func decode(_ type: String.Type, forKey key: K) throws -> String {
		guard let value = dict[key.stringValue] as? String else {
			throw DictDecoderError.missingValueForKey(key.stringValue)
		}
		return value
	}

	func decode(_ type: Data.Type, forKey key: K) throws -> Data {
		guard let value = dict[key.stringValue] as? Data else {
			throw DictDecoderError.missingValueForKey(key.stringValue)
		}
		return value
	}

	func decode(_ type: Date.Type, forKey key: K) throws -> Date {
		let string = try decode(String.self, forKey: key)
		if let date = ALBNoSQLDB.dateFormatter.date(from: string) {
			return date
		} else {
			throw DictDecoderError.invalidDate(string)
		}
	}

	func decode(_ type: URL.Type, forKey key: K) throws -> URL {
		let string = try decode(String.self, forKey: key)
		if let url = URL(string: string) {
			return url
		} else {
			throw DictDecoderError.invalidURL(string)
		}
	}

	func decode(_ type: UUID.Type, forKey key: K) throws -> UUID {
		let string = try decode(String.self, forKey: key)
		if let uuid = UUID(uuidString: string) {
			return uuid
		} else {
			throw DictDecoderError.invalidUUID(string)
		}
	}

	func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
		if Data.self == T.self {
			return try decode(Data.self, forKey: key) as! T
		} else if Date.self == T.self {
			return try decode(Date.self, forKey: key) as! T
		} else if URL.self == T.self {
			return try decode(URL.self, forKey: key) as! T
		} else if UUID.self == T.self {
			return try decode(UUID.self, forKey: key) as! T
		} else if Bool.self == T.self {
			return try decode(Bool.self, forKey: key) as! T
		} else {
			let jsonText = try decode(String.self, forKey: key)
			guard let jsonData = jsonText.data(using: .utf8) else {
				throw DictDecoderError.invalidJSON(jsonText)
			}
			return try JSONDecoder().decode(T.self, from: jsonData)
		}
	}

	func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
		fatalError("_KeyedContainer does not support nested containers.")
	}

	func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
		fatalError("_KeyedContainer does not support nested containers.")
	}

	func superDecoder() throws -> Decoder {
		fatalError("_KeyedContainer does not support nested containers.")
	}

	func superDecoder(forKey key: K) throws -> Decoder {
		fatalError("_KeyedContainer does not support nested containers.")
	}
}

private class DictDecoder: Decoder {
	var codingPath: Array<CodingKey> = []
	var userInfo: Dictionary<CodingUserInfoKey, Any> = [:]

	var dict: [String: AnyObject]?

	init(_ dict: [String: AnyObject]) {
		self.dict = dict
	}

	func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
		guard let row = self.dict else { fatalError() }
		return KeyedDecodingContainer(DictKeyedContainer<Key>(row))
	}

	func unkeyedContainer() throws -> UnkeyedDecodingContainer {
		fatalError("SQLiteDecoder doesn't support unkeyed decoding")
	}

	func singleValueContainer() throws -> SingleValueDecodingContainer {
		fatalError("SQLiteDecoder doesn't support single value decoding")
	}
}
