# ALBNoSQLDB
[![CocoaPods](https://img.shields.io/cocoapods/v/ALBNoSQLDB.svg)](https://cocoapods.org/)


**This class uses Swift 5.**

A SQLite database wrapper written in Swift that requires no SQL knowledge to use.

No need to keep track of columns used in the database; it's automatic.

Completely thread safe since it uses it's own Thread subclass.

## What's new in version 5.1 ##
- Developed and tested with Xcode 10.2 using Swift 5
- Introduction of DBObject protocol. See below.
- debugMode property renamed to isDebugging.

## What's new in version 5 ##
- Developed and tested with Xcode 10.1
- Several methods deprecated with a renamed version available for clarity at the point of use.
- Data can be retrieved asynchronously.
- The class property `sharedInstance` has been renamed to `shared`.
- Methods are no longer class-level, they must be accessed through an instance of the db. A simple way to update to this is to simply append .shared to the class name in any existing code.

## Installation Options ##
- Cocoapods `pod ALBNoSQLDB`
- Include ALBNoSQLDB.swift and DBOject.swift files in your project

## Getting Started ##
ALBNoSQLDB acts as a key/value database allowing you to set a JSON value in a table for a specific key or getting keys from a table.

Supported types in the JSON are string, int, double, bool and arrays of string, int, or double off the base object.

If a method returns an optional, that value is nil if an error occured and could not return a proper value.

### Keys ###

See if a given table holds a given key.
```swift
let table: DBTable = "categories"
if let hasKey = ALBNoSQLDB.shared.tableHasKey(table:table, key:"category1") {
    // process here
    if hasKey {
        // table has key
    } else {
        // table didn't have key
    }
} else {
    // handle error
}
```

Return an array of keys in a given table. Optionally specify sort order based on a value at the root level
```swift
let table: DBTable = "categories"
if let tableKeys = ALBNoSQLDB.shared.keysInTable(table, sortOrder:"name, date desc") }
    // process keys
} else {
    // handle error
}
```

Return an array of keys in a given table matching a set of conditions. (see class documentation for more information)
```swift
let table: DBTable = "accounts"
let accountCondition = DBCondition(set:0,objectKey:"account", conditionOperator:.equal, value:"ACCT1")
if let keys = ALBNoSQLDB.shared.keysInTable(table, sortOrder: nil, conditions: [accountCondition]) {
    // process keys
} else {
    // handle error
}
```



### Values ###
Data can be set or retrieved manually as shown here or your class/struct can adhere to the DBObject protocol, documented below, and use the built-in init and save methods.

Set value in table
```swift
let table: DBTable = "categories"
let jsonValue = "{\"numValue\":1,\"name\":\"Account Category\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}"
if ALBNoSQLDB.shared.setValueInTable(table, for:"category1", to:jsonValue, autoDeleteAfter:nil) {
    // value was set properly
} else {
    // handle error
}
```

Retrieve value for a given key
```swift
let table: DBTable = "categories"
if let jsonValue = ALBNoSQLDB.shared.valueFromTable(table, for:"category1") {
    // process value
} else {
    // handle error
}

if let dictValue = ALBNoSQLDB.shared.dictValueFromTable(table, for:"category1") {
    // process dictionary value
} else {
    // handle error
}
```

Delete the value for a given key
```swift
let table: DBTable = "categories"
if ALBNoSQLDB.shared.deleteFromTable(table, for:"category1") {
    // value was deleted
} else {
    // handle error
}
```

## Retrieving Data Asynchronously ##
With version 5, ALBNoSQLDB allows data to be retrieved asynchronously. A DBCommandToken is returned that allows the command to be canceled before it is acted upon. For instance, a database driven TableView may be scrolled too quickly for the viewing of data to useful. In the prepareForReuse method, the token's cancel method could be called so the database is not tasked in retrieving data for a cell that is no longer viewed.

```swift
let db = ALBNoSQLDB.shared
let table: DBTable = "categories"

guard let token = db.valueFromTable(table, for: key, completion: { (results) in
	if case .success(let value) = results {
		// use value
	} else {
		// error
	}
}) else {
	XCTFail("Unable to get value")
	return
}

// save token for later use
self.token = token

// cancel operation
let successful = token.cancel()
```

*Asynchronous methods available*
- tableHasKey
- keysInTable
- valueFromTable
- dictValueFromTable
- sqlSelect
- loadObjectFromDB in the DBObject protocol

## SQL Queries ##
ALBNoSQLDB allows you to do standard SQL selects for more complex queries. Because the values given are actually broken into separate columns in the tables, a standard SQL statement can be passed in and an array of rows (arrays of values) will be optionally returned.

```
let db = ALBNoSQLDB.shared
let sql = "select name from accounts a inner join categories c on c.accountKey = a.key order by a.name"
if let results = db.sqlSelect(sql) {
    // process results
} else {
    // handle error
}
```

## Syncing ##
ALBNoSQLDB can sync with other instances of itself by enabling syncing before processing any data and then sharing a sync log.

```swift
/**
Enables syncing. Once enabled, a log is created for all current values in the tables.

- returns: Bool If syncing was successfully enabled.
*/
public func enableSyncing() -> Bool


/**
Disables syncing.

- returns: Bool If syncing was successfully disabled.
*/
public func disableSyncing() -> Bool
	

/**
Read-only array of unsynced tables. Any tables not in this array will be synced.
*/
var unsyncedTables: [String]

/**
Sets the tables that are not to be synced.

- parameter tables: Array of tables that are not to be synced.

- returns: Bool If list was set successfully.
*/
public func setUnsyncedTables(_ tables: [String]) -> Bool


/**
Creates a sync file that can be used on another ALBNoSQLDB instance to sync data. This is a synchronous call.

- parameter filePath: The full path, including the file itself, to be used for the log file.
- parameter lastSequence: The last sequence used for the given target  Initial sequence is 0.
- parameter targetDBInstanceKey: The dbInstanceKey of the target database. Use the dbInstanceKey method to get the DB's instanceKey.

- returns: (Bool,Int) If the file was successfully created and the lastSequence that should be used in subsequent calls to this instance for the given targetDBInstanceKey.
*/
public func createSyncFileAtURL(_ localURL: URL!, lastSequence: Int, targetDBInstanceKey: String) -> (Bool, Int)


/**
Processes a sync file created by another instance of ALBNoSQL This is a synchronous call.

- parameter filePath: The path to the sync file.
- parameter syncProgress: Optional function that will be called periodically giving the percent complete.

- returns: (Bool,String,Int)  If the sync file was successfully processed,the instanceKey of the submiting DB, and the lastSequence that should be used in subsequent calls to the createSyncFile method of the instance that was used to create this file. If the database couldn't be opened or syncing hasn't been enabled, then the instanceKey will be empty and the lastSequence will be equal to zero.
*/
public typealias syncProgressUpdate = (_ percentComplete: Double) -> Void
public func processSyncFileAtURL(_ localURL: URL!, syncProgress: syncProgressUpdate?) -> (Bool, String, Int)
```	
	

## DBObject Protocol ##
Create classes or structs that adhere to the DBObject Protocol and you can instantiate objects that are automatically populated with data from the database synchronously or asynchronously and save the data to the database.
Note that the protocol adheres to the Codable protocol and will require a CodingKey enum to function properly.
Bool properties read from the database will be interpreted as follows: An integer 0 = false and any other number is true or a string where "1" or any case "yes" or "true" = true.

### Protocol Definition ###
```swift
public protocol DBObject: Codable {
	static var table: DBTable { get }
	var key: String { get set }
}
```

### Protocol methods ###
```swift
/**
 Instantiate object and populate with values from the database. If instantiation fails, nil is returned.

 - parameter db: Database object holding the data.
 - parameter key: Key of the data entry.
*/
public init?(db: ALBNoSQLDB, key: String)


/**
 Save the object to the database based on the values set in the encode method of the object.

 - parameter db: Database object to hold the data.
 - parameter expiration: Optional Date specifying when the data is to be automatically deleted. Default value is nil specifying no automatic deletion.

 - returns: Discardable Bool value of a successful save.
*/
@discardableResult
public func save(to db: ALBNoSQLDB, autoDeleteAfter expiration: Date? = nil) -> Bool


/**
 Asynchronously instantiate object and populate with values from the database before executing the passed block with object. If object could not be instantiated properly, block is not executed.

 - parameter db: Database object to hold the data.
 - parameter key: Key of the data entry.
 - parameter queue: DispatchQueue to run the execution block on. Default value is nil specifying the main queue.
 - parameter block: Block of code to execute with instantiated object.

 - returns: DBCommandToken that can be used to cancel the call before it executes. Nil is returned if database could not be opened.
*/
public static func loadObjectFromDB(_ db: ALBNoSQLDB, for key: String, queue: DispatchQueue? = nil, completion: @escaping (Self) -> Void) -> DBCommandToken?

```

### Sample Struct ###
```swift
import ALBNoSQLDB

enum Table: String {
	case categories = "Categories"
    
	var dbTable: DBTable {
        return DBTable(name: self.rawValue)
    }
}

struct Category: DBObject {
	static var table: DBTable { return Table.categories.dbTable }
	var key = UUID().uuidString
	var accountKey = ""
	var name = ""
	var inSummary = true

	private enum CategoryKey: String, CodingKey {
		case key, accountKey, name, inSummary
	}

	init() { }

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CategoryKey.self)

		key = try container.decode(String.self, forKey: .key)
		accountKey = try container.decode(String.self, forKey: .accountKey)
		name = try container.decode(String.self, forKey: .name)
		inSummary = try container.decode(Bool.self, forKey: .inSummary)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CategoryKey.self)

		try container.encode(accountKey, forKey: .accountKey)
		try container.encode(name, forKey: .name)
		try container.encode(inSummary, forKey: .inSummary)
	}
}

// instantiate synchronously
guard let category = Category(db: db, key: categoryKey) else { return }

// instantiate asynchronously
let token = Category.loadObjectFromDB(db, for: categoryKey) { (category) in
	// use category object
}

```
