# ALBNoSQLDB
**This class uses Swift 1.2**

A SQLite database wrapper written in Swift that requires no SQL knowledge to use.

All public methods are class-level methods, so no instance of the class is needed.

See the Shopping project for an example of using this class to sync between instances of an app.

## Getting Started ##
ALBNoSQLDB acts as a key/value database allowing you to set a JSON value in a table for a specific key or getting keys from a table.

Supported types in the JSON are string, int, double, and arrays of these types off the base object.

If a method returns an optional, that value is nil if an error occured and could not return a proper value

### Keys ###

See if a given table holds a given key.
```swift
if let hasKey = ALBNoSQLDB.tableHasKey(table:"categories", key:"category1") {
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
if let tableKeys = ALBNoSQLDB.keysInTable(table:"categories", sortOrder:"name") }
    // process keys
} else {
    // handle error
}
```

Return an array of keys in a given table matching a set of conditions. (see class documentation for more information)
```swift
let accountCondition = DBCondition(set:0,objectKey:"account",conditionOperator:.equal, value:"ACCT1")
if let keys = ALBNoSQLDB.keysInTableForConditions("accounts", sortOrder: nil, conditions: [accountCondition]) {
    // process keys
} else {
    // handle error
}
```



### Values ###
Set value in table
```swift
let jsonValue = "{\"numValue\":1,\"name\":\"Account Category\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}"
if ALBNoSQLDB.setValue(table:"categories", key:"category1", value:jsonValue, autoDeleteAfter:nil) {
    // value was set properly
} else {
    // handle error
}
```

Retrieve value for a given key
```swift
if let jsonValue = ALBNoSQLDB.valueForKey(table:"categories", key:"category1") {
    // process value
} else {
    // handle error
}

if let dictValue = ALBNoSQLDB.dictValueForKey(table:"categories", key:"category1") {
    // process dictionary value
} else {
    // handle error
}
```

Delete the value for a given key
```swift
if ALBNoSQLDB.deleteForKey(table:"categories", key:"category1") {
    // value was deleted
} else {
    // handle error
}
```

## SQL Queries ##
ALBNoSQLDB allows you to do standard SQL selects for more complex queries. Because the values given are actually broken into separate columns in the tables, a standard SQL statement can be passed in and an array of rows (arrays of values) will be optionally returned.

```swift
let db = ALBNoSQLDB.sharedInstance
let sql = "select name from accounts a inner join categories c on c.accountKey = a.key order by a.name"
if let results = db.sqlSelect(sql) {
    // process results
} else {
    // handle error
}
```

## Syncing ##
ALBNoSQLDB can sync with other instances of itself by enabling syncing before processing any data and then sharing a sync log. See methods and documentation in class


