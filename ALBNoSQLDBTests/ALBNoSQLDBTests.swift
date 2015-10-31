//
//  ALBNoSQLDBTests.swift
//  ALBNoSQLDBTests
//
//  Created by Aaron Bratcher on 1/8/15.
//  Copyright (c) 2015 Aaron Bratcher. All rights reserved.
//

import UIKit
import XCTest

class ALBNoSQLDBTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let searchPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentFolderPath = searchPaths[0] 
        let dbFilePath = documentFolderPath+"/TestDB.db"
        
        ALBNoSQLDB.setFileLocation(NSURL(fileURLWithPath: dbFilePath))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEmptyInsert() {
        let key = "emptykey"
        
        let successful = ALBNoSQLDB.setValue(table: "table1", key: key, value: "{}", autoDeleteAfter: nil)
        XCTAssert(successful, "setValueFailed")
        
        let jsonValue = ALBNoSQLDB.valueForKey(table: "table1", key: key)
        XCTAssert(jsonValue != nil, "No value returned")
    }
    
    func testSimpleInsert() {
        let key = "SIMPLEINSERTKEY"
        let sample = "{\"numValue\":1,\"dateValue\":\"2014-11-19T18:23:42.434-05:00\"}"
        let sampleData = sample.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let sampleDict = (try? NSJSONSerialization.JSONObjectWithData(sampleData, options: NSJSONReadingOptions.MutableContainers)) as? [String:AnyObject]
        let successful = ALBNoSQLDB.setValue(table: "table1", key: key, value: sample, autoDeleteAfter: nil)
        
        XCTAssert(successful, "setValueFailed")
        
        let jsonValue = ALBNoSQLDB.valueForKey(table: "table1", key: key)
        
        XCTAssert(jsonValue != nil, "No value returned")
        
        // compare dict values
        if let jsonValue = jsonValue {
            let dataValue = jsonValue.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            let objectValues = (try? NSJSONSerialization.JSONObjectWithData(dataValue, options: NSJSONReadingOptions.MutableContainers)) as? [String:AnyObject]
            let equalDicts = objectValues?.count == sampleDict?.count
            XCTAssert(equalDicts, "Dictionaries don't match")
        }
    }
    
    
    func testArrayInsert() {
        let key = "ARRAYINSERTKEY"
        let sample = "{\"numValue\":1,\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5],\"array2Value\":[\"1\",\"b\"]}"
        let sampleData = sample.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let sampleDict = (try? NSJSONSerialization.JSONObjectWithData(sampleData, options: NSJSONReadingOptions.MutableContainers)) as? [String:AnyObject]
        let successful = ALBNoSQLDB.setValue(table: "table1", key: key, value: sample, autoDeleteAfter: nil)
        
        XCTAssert(successful, "setValueFailed")
        
        let jsonValue = ALBNoSQLDB.valueForKey(table: "table1", key: key)
        
        XCTAssert(jsonValue != nil, "No value returned")
        
        // compare dict values
        if let jsonValue = jsonValue {
            let dataValue = jsonValue.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            let objectValues = (try? NSJSONSerialization.JSONObjectWithData(dataValue, options: NSJSONReadingOptions.MutableContainers)) as? [String:AnyObject]
            let equalDicts = objectValues?.count == sampleDict?.count
            XCTAssert(equalDicts, "Dictionaries don't match")
            
            let array = objectValues!["arrayValue"] as! [Int]
            var properArray = array.filter({$0==1}).count == 1 && array.filter({$0==2}).count == 1 && array.filter({$0==3}).count == 1 && array.filter({$0==4}).count == 1 && array.filter({$0==5}).count == 1
            
            XCTAssert(properArray, "improper Array")
            
            let array2 = objectValues!["array2Value"] as! [String]
            properArray = array2.filter({$0=="1"}).count == 1 && array2.filter({$0=="b"}).count == 1
            
            XCTAssert(properArray, "improper Array2")
        }
    }
    
    
    func testChange() {
        let key = "AABBCC3"
        let firstSample = "{\"numValue\":1,\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}"
        var successful = ALBNoSQLDB.setValue(table: "table1", key: key, value: firstSample, autoDeleteAfter: nil)
        
        XCTAssert(successful, "setValueFailed")
        
        let sample = "{\"numValue\":2,\"arrayValue\":[6,7,8,9,10]}"
        successful = ALBNoSQLDB.setValue(table: "table1", key: key, value: sample, autoDeleteAfter: nil)
        
        XCTAssert(successful, "setValueFailed")
        
        let jsonValue = ALBNoSQLDB.valueForKey(table: "table1", key: key)
        
        XCTAssert(jsonValue != nil, "No value returned")
        
        // compare dict values
        if let jsonValue = jsonValue {
            let dataValue = jsonValue.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
            let objectValues = (try? NSJSONSerialization.JSONObjectWithData(dataValue, options: NSJSONReadingOptions.MutableContainers)) as? [String:AnyObject]
            let numValue = objectValues!["numValue"] as! Int
            
            XCTAssert(numValue == 2, "number didn't change properly")
            
            let dateValue: AnyObject? = objectValues!["dateValue"]
            
            XCTAssert(dateValue == nil, "date still exists")
            
            let array = objectValues!["arrayValue"] as! [Int]
            let properArray = array.filter({$0==6}).count == 1 && array.filter({$0==7}).count == 1 && array.filter({$0==8}).count == 1 && array.filter({$0==9}).count == 1 && array.filter({$0==10}).count == 1
            
            XCTAssert(properArray, "improper Array")
        }
    }
    
    func testTableHasKey() {
        let sample = "{\"numValue\":2,\"arrayValue\":[6,7,8,9,10]}"
        
        ALBNoSQLDB.setValue(table: "table0", key: "testKey1", value: sample, autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table0", key: "testKey2", value: sample, autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table0", key: "testKey3", value: sample, autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table0", key: "testKey4", value: sample, autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table0", key: "testKey5", value: sample, autoDeleteAfter: nil)
        
        if let hasKey = ALBNoSQLDB.tableHasKey(table: "table0", key: "testKey4") {
            XCTAssert(hasKey, "invalid test result")
        } else {
            XCTAssert(false, "bool not returned")
        }
        
    }
    
    
    func testKeyFetch() {
        let sample = "{\"numValue\":2,\"arrayValue\":[6,7,8,9,10]}"
        
        ALBNoSQLDB.setValue(table: "table2", key: "testKey1", value: sample, autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table2", key: "testKey2", value: sample, autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table2", key: "testKey3", value: sample, autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table2", key: "testKey4", value: sample, autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table2", key: "testKey5", value: sample, autoDeleteAfter: nil)
        
        if let keys = ALBNoSQLDB.keysInTable("table2", sortOrder: nil) {
            let properArray = keys.filter({$0=="testKey1"}).count == 1 && keys.filter({$0=="testKey2"}).count == 1 && keys.filter({$0=="testKey3"}).count == 1 && keys.filter({$0=="testKey4"}).count == 1 && keys.filter({$0=="testKey5"}).count == 1
            
            XCTAssert(properArray, "improper keys")
        } else {
            XCTAssert(false, "keys not returned")
        }
    }
    
    func testOrderedKeyFetch() {
        ALBNoSQLDB.setValue(table: "table3", key: "testKey1", value: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table3", key: "testKey2", value: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table3", key: "testKey3", value: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table3", key: "testKey4", value: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table3", key: "testKey5", value: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)
        
        if let keys = ALBNoSQLDB.keysInTable("table3", sortOrder: "numValue,value2") {
            let properArray = keys[0] == "testKey4" && keys[1] == "testKey1" && keys[2] == "testKey5" && keys[3] == "testKey3" && keys[4] == "testKey2"
            
            XCTAssert(properArray, "improper keys")
        } else {
            XCTAssert(false, "keys not returned")
        }
    }
    
    func testDescendingKeyFetch() {
        ALBNoSQLDB.setValue(table: "table4", key: "testKey1", value: "{\"numValue\":2,\"value2\":1}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table4", key: "testKey2", value: "{\"numValue\":3,\"value2\":1}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table4", key: "testKey3", value: "{\"numValue\":2,\"value2\":3}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table4", key: "testKey4", value: "{\"numValue\":1,\"value2\":1}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table4", key: "testKey5", value: "{\"numValue\":2,\"value2\":2}", autoDeleteAfter: nil)
        
        if let keys = ALBNoSQLDB.keysInTable("table4", sortOrder: "numValue desc,value2 desc") {
            let properArray = keys[0] == "testKey2" && keys[1] == "testKey3" && keys[2] == "testKey5" && keys[3] == "testKey1" && keys[4] == "testKey4"
            
            XCTAssert(properArray, "improper keys")
        } else {
            XCTAssert(false, "keys not returned")
        }
    }
    
    func testMissingKeyCondition() {
        ALBNoSQLDB.setValue(table: "table51", key: "testKey1", value: "{\"numValue\":1}", autoDeleteAfter: nil)
        
        let accountCondition = DBCondition(set:0,objectKey:"account",conditionOperator:.equal, value:"ACCT1")
        if let keys = ALBNoSQLDB.keysInTableForConditions("table51", sortOrder: nil, conditions: [accountCondition]) {
            XCTAssert(keys.count == 0, "Keys shouldnt exist")
        } else {
            XCTAssert(false, "no keys object returned")
        }
        
        let keyCondition = DBCondition(set:0,objectKey:"key",conditionOperator:.equal, value:"ACCT1")
        if let keys = ALBNoSQLDB.keysInTableForConditions("table51", sortOrder: nil, conditions: [keyCondition]) {
            XCTAssert(keys.count == 0, "Keys shouldnt exist")
        } else {
            XCTAssert(false, "no keys object returned")
        }
        
    }
    
    func testSimpleConditionKeyFetch() {
        ALBNoSQLDB.setValue(table: "table5", key: "testKey1", value: "{\"numValue\":1,\"account\":\"ACCT's 1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table5", key: "testKey2", value: "{\"numValue\":2,\"account\":\"ACCT's 1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table5", key: "testKey3", value: "{\"numValue\":3,\"account\":\"ACCT2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table5", key: "testKey4", value: "{\"numValue\":4,\"account\":\"ACCT2\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table5", key: "testKey5", value: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)
        
        let accountCondition = DBCondition(set:0,objectKey:"account",conditionOperator:.equal, value:"ACCT's 1")
        let numCondition = DBCondition(set:0,objectKey:"numValue",conditionOperator:.greaterThan,value:1)
        
        if let keys = ALBNoSQLDB.keysInTableForConditions("table5", sortOrder: nil, conditions: [accountCondition,numCondition]) {
            XCTAssert(keys.count == 1 && keys[0] == "testKey2", "invalid key")
        } else {
            XCTAssert(false, "keys not returned")
        }
    }
    
    func testContainsCondition() {
        ALBNoSQLDB.setTableIndexes(table: "table6", indexes: ["account"])
        
        ALBNoSQLDB.setValue(table: "table6", key: "testKey1", value: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table6", key: "testKey2", value: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table6", key: "testKey3", value: "{\"numValue\":3,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table6", key: "testKey4", value: "{\"numValue\":4,\"account\":\"TEST3\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table6", key: "testKey5", value: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)
        
        let acctCondition = DBCondition(set:0,objectKey:"account",conditionOperator:.contains, value:"ACCT")
        let arrayCondition = DBCondition(set: 1, objectKey: "arrayValue", conditionOperator: .contains, value: 10)
        
        if let keys = ALBNoSQLDB.keysInTableForConditions("table6", sortOrder: nil, conditions: [acctCondition,arrayCondition]) {
            let success = keys.count == 3 && (keys.filter({$0=="testKey1"}).count == 1 && keys.filter({$0=="testKey5"}).count == 1 && keys.filter({$0=="testKey2"}).count == 1)
            XCTAssert(success, "invalid keys")
        } else {
            XCTAssert(false, "keys not returned")
        }
    }
    
    func testEmptyCondition() {
        ALBNoSQLDB.setValue(table: "table61", key: "testKey1", value: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table61", key: "testKey2", value: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table61", key: "testKey3", value: "{\"numValue\":3,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table61", key: "testKey4", value: "{\"numValue\":4,\"account\":\"TEST3\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table61", key: "testKey5", value: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)
        
        let conditionArray = [DBCondition]()
        
        if let keys = ALBNoSQLDB.keysInTableForConditions("table61", sortOrder: nil, conditions: conditionArray) {
            let success = keys.count == 5
            XCTAssert(success, "invalid keys")
        } else {
            XCTAssert(false, "keys not returned")
        }
    }
    
    func testDeletion() {
        ALBNoSQLDB.setValue(table: "table6", key: "testKey41", value: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
        XCTAssert(ALBNoSQLDB.deleteForKey(table: "table6", key: "testKey41"), "deletion failed")
        XCTAssert(!ALBNoSQLDB.tableHasKey(table: "table6", key: "testKey41")!, "key still exists")
    }
    
    
    func testDropTable() {
        ALBNoSQLDB.setValue(table: "table7", key: "testKey1", value: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table7", key: "testKey2", value: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table7", key: "testKey3", value: "{\"numValue\":3,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table7", key: "testKey4", value: "{\"numValue\":4,\"account\":\"TEST3\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table7", key: "testKey5", value: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)
        
        _ = ALBNoSQLDB.dropTable("table7")
        if let keys = ALBNoSQLDB.keysInTable("table7", sortOrder: nil) {
            XCTAssert(keys.count == 0, "keys were returned when table should be empty")
        } else {
            XCTAssert(false, "keys not returned")
        }
    }
    
    func testDropAllTables() {
        ALBNoSQLDB.setValue(table: "table8", key: "testKey1", value: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table9", key: "testKey2", value: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table10", key: "testKey3", value: "{\"numValue\":3,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table11", key: "testKey4", value: "{\"numValue\":4,\"account\":\"TEST3\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table12", key: "testKey5", value: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)
        
        _ = ALBNoSQLDB.dropAllTables()
        if let keys = ALBNoSQLDB.keysInTable("table8", sortOrder: nil) {
            XCTAssert(keys.count == 0, "keys were returned when table should be empty")
        } else {
            XCTAssert(false, "keys not returned")
        }
        
        if let keys = ALBNoSQLDB.keysInTable("table9", sortOrder: nil) {
            XCTAssert(keys.count == 0, "keys were returned when table should be empty")
        } else {
            XCTAssert(false, "keys not returned")
        }
        
        if let keys = ALBNoSQLDB.keysInTable("table10", sortOrder: nil) {
            XCTAssert(keys.count == 0, "keys were returned when table should be empty")
        } else {
            XCTAssert(false, "keys not returned")
        }
        if let keys = ALBNoSQLDB.keysInTable("table11", sortOrder: nil) {
            XCTAssert(keys.count == 0, "keys were returned when table should be empty")
        } else {
            XCTAssert(false, "keys not returned")
        }
        
        if let keys = ALBNoSQLDB.keysInTable("table12", sortOrder: nil) {
            XCTAssert(keys.count == 0, "keys were returned when table should be empty")
        } else {
            XCTAssert(false, "keys not returned")
        }
    }
    
    
    //    func testPerformanceExample() {
    //        // This is an example of a performance test case.
    //        self.measureBlock() {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }
    
}
