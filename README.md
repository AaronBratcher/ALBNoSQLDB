# ALBNoSQLDB
[![CocoaPods](https://img.shields.io/cocoapods/v/ALBNoSQLDB.svg)](https://cocoapods.org/)


**This class uses Swift 4.0.**

A SQLite database wrapper written in Swift that requires no SQL knowledge to use.

No need to keep track of columns used in the database; it's automatic.

Completely thread safe since it uses it's own Thread subclass.

## What's new in version 5 ##
- Developed and tested with Xcode 10.1
- Several methods deprecated with a renamed version available for clarity at the point of use.
- Data can be retrieved asynchronously.

## Breaking Changes ##
- The class property `sharedInstance` has been renamed to `shared`.
- Methods are no longer class-level, they must be accessed through an instance of the db. A simple way to update to this is to simply append .shared to the class name in any existing code.

## Installation Options ##
- Cocoapods `pod ALBNoSQLDB`
- Include ALBNoSQLDB.swift in your project

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
if let tableKeys = ALBNoSQLDB.shared.keysInTable(table:"categories", sortOrder:"name, date desc") }
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

guard let token = db.valueFromTable(table, for: key, completion: { (value) in
	// process value
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

## SQL Queries ##
ALBNoSQLDB allows you to do standard SQL selects for more complex queries. Because the values given are actually broken into separate columns in the tables, a standard SQL statement can be passed in and an array of rows (arrays of values) will be optionally returned.

```swift
let db = ALBNoSQLDB.shared
let sql = "select name from accounts a inner join categories c on c.accountKey = a.key order by a.name"
if let results = db.sqlSelect(sql) {
    // process results
} else {
    // handle error
}
```

## Syncing ##
ALBNoSQLDB can sync with other instances of itself by enabling syncing before processing any data and then sharing a sync log. See methods and documentation in class


