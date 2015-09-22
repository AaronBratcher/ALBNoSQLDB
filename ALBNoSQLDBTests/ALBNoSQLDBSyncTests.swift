//
//  ALBNoSQLDBSyncTests.swift
//  ALBNoSQLDB
//
//  Created by Aaron Bratcher on 1/15/15.
//  Copyright (c) 2015 Aaron Bratcher. All rights reserved.
//

import Foundation
import XCTest

class ALBNoSQLDBSyncTests: XCTestCase {
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
    
    func testEnableSyncing() {
        XCTAssert(ALBNoSQLDB.enableSyncing(), "Could not enable syncing")
    }
    
    func testDisableSyncing() {
        XCTAssert(ALBNoSQLDB.disableSyncing(), "Could not disable syncing")
    }
    
    func testCreateSyncFile() {
        ALBNoSQLDB.disableSyncing()
        ALBNoSQLDB.dropAllTables()
        ALBNoSQLDB.enableSyncing()
        
        ALBNoSQLDB.setValue(table: "table8", key: "testKey1", value: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
        ALBNoSQLDB.deleteForKey(table: "table8", key: "testKey1")
        
        
        ALBNoSQLDB.setValue(table: "table9", key: "testKey2", value: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
        
        ALBNoSQLDB.setValue(table: "table9", key: "testKey1", value: "{\"numValue\":1,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\"}", autoDeleteAfter: nil)
        
        ALBNoSQLDB.setValue(table: "table10", key: "testKey3", value: "{\"numValue\":3,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table10", key: "testKey3", value: "{\"numValue\":3,\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12]}", autoDeleteAfter: nil)
        
        ALBNoSQLDB.setValue(table: "table11", key: "testKey4", value: "{\"numValue\":4,\"account\":\"TEST3\",\"dateValue\":\"2014-11-19T18:23:42.434-05:00\",\"arrayValue\":[16,17,18,19,20]}", autoDeleteAfter: nil)
        ALBNoSQLDB.deleteForKey(table: "table11", key: "testKey4")
        
        ALBNoSQLDB.setValue(table: "table12", key: "testKey5", value: "{\"numValue\":5,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)
        ALBNoSQLDB.dropTable("table9")
        
        let searchPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentFolderPath = searchPaths[0] 
        let logFilePath = documentFolderPath+"/testSyncLog.txt"
        print(logFilePath)
        let fileURL = NSURL(fileURLWithPath: logFilePath)
        
        let (complete,lastSequence) = ALBNoSQLDB.createSyncFileAtURL(fileURL, lastSequence: 0, targetDBInstanceKey: "TEST-DB-INSTANCE")
        
        XCTAssert(complete, "sync file not completed")
        XCTAssert(lastSequence == 10, "lastSequence is incorrect")
        
        // read in file and make sure it is valid JSON
        if let fileHandle = NSFileHandle(forReadingAtPath: logFilePath) {
            let dataValue = fileHandle.readDataToEndOfFile()
            if let objectValues = (try? NSJSONSerialization.JSONObjectWithData(dataValue, options: NSJSONReadingOptions.MutableContainers)) as? [String:AnyObject] {
                
            } else {
                XCTAssert(false, "invalid sync file format")
            }
        } else {
            XCTAssert(false, "cannot open file")
        }
    }
    
    func testProcessSyncFile() {
        ALBNoSQLDB.disableSyncing()
        ALBNoSQLDB.dropAllTables()
        ALBNoSQLDB.enableSyncing()
        
        // will be deleted
        ALBNoSQLDB.setValue(table: "table8", key: "testKey1", value: "{\"numValue\":10,\"account\":\"ACCT1\",\"dateValue\":\"2014-8-19T18:23:42.434-05:00\",\"arrayValue\":[1,2,3,4,5]}", autoDeleteAfter: nil)
        
        // these entries will be deleted because of a drop table
        ALBNoSQLDB.setValue(table: "table9", key: "testKey2", value: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table9", key: "testKey3", value: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table9", key: "testKey4", value: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
        ALBNoSQLDB.setValue(table: "table9", key: "testKey5", value: "{\"numValue\":2,\"account\":\"TEST1\",\"dateValue\":\"2014-9-19T18:23:42.434-05:00\",\"arrayValue\":[6,7,8,9,10]}", autoDeleteAfter: nil)
        
        // this value will be unchanged due to timeStamp
        ALBNoSQLDB.setValue(table: "table10", key: "testKey3", value: "{\"numValue\":13,\"account\":\"TEST2\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"arrayValue\":[11,12,13,14,15]}", autoDeleteAfter: nil)
        
        // this value will be updated
        ALBNoSQLDB.setValue(table: "table12", key: "testKey5", value: "{\"numValue\":15,\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"arrayValue\":[21,22,23,24,25]}", autoDeleteAfter: nil)
        
        let syncFileContents = "{\"sourceDB\":\"58D200A048F9\",\"lastSequence\":1000,\"logEntries\":[{\"timeStamp\":\"2020-01-15T16:22:55.231-05:00\",\"key\":\"testKey1\",\"activity\":\"D\",\"tableName\":\"table8\"},{\"timeStamp\":\"2010-01-15T16:22:55.262-05:00\",\"value\":{\"addedDateTime\":\"2015-01-15T16:22:55.246-05:00\",\"dateValue\":\"2014-10-19T18:23:42.434-05:00\",\"numValue\":3,\"updatedDateTime\":\"2015-01-15T16:22:55.258-05:00\",\"arrayValue\":[11,12]},\"key\":\"testKey3\",\"activity\":\"U\",\"tableName\":\"table10\"},{\"timeStamp\":\"2015-01-15T16:22:55.276-05:00\",\"key\":\"testKey4\",\"activity\":\"D\",\"tableName\":\"table11\"},{\"timeStamp\":\"2020-01-15T16:22:55.288-05:00\",\"value\":{\"addedDateTime\":\"2015-01-15T16:22:55.277-05:00\",\"account\":\"ACCT3\",\"dateValue\":\"2014-12-19T18:23:42.434-05:00\",\"numValue\":5,\"updatedDateTime\":\"2015-01-15T16:22:55.277-05:00\",\"arrayValue\":[21,22,23,24,25]},\"key\":\"testKey5\",\"activity\":\"U\",\"tableName\":\"table12\"},{\"tableName\":\"table9\",\"activity\":\"X\",\"timeStamp\":\"2020-01-15T16:22:55.290-05:00\"}]}"
        
        let searchPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentFolderPath = searchPaths[0] 
        let logFilePath = documentFolderPath+"/testSyncLog2.txt"
        
        NSFileManager.defaultManager().createFileAtPath(logFilePath, contents: nil, attributes: nil)
        if let fileHandle = NSFileHandle(forWritingAtPath: logFilePath) {
            fileHandle.writeData(syncFileContents.dataValue())
            fileHandle.closeFile()
            let fileURL = NSURL(fileURLWithPath: logFilePath)
            
            let (results,dbKey,lastSequence) = ALBNoSQLDB.processSyncFileAtURL(fileURL, syncProgress: nil)
            XCTAssert(results, "sync log not processed")
            
            // check for proper changes
            XCTAssert(!ALBNoSQLDB.tableHasKey(table: "table8", key: "testKey1")!, "table8 still has entry")
            
            XCTAssert(!ALBNoSQLDB.tableHasKey(table: "table9", key: "testKey2")!, "drop table 9 failed")
            XCTAssert(!ALBNoSQLDB.tableHasKey(table: "table9", key: "testKey3")!, "drop table 9 failed")
            XCTAssert(!ALBNoSQLDB.tableHasKey(table: "table9", key: "testKey4")!, "drop table 9 failed")
            XCTAssert(!ALBNoSQLDB.tableHasKey(table: "table9", key: "testKey5")!, "drop table 9 failed")
            
            var jsonValue = ALBNoSQLDB.valueForKey(table: "table10", key: "testKey3")
            // compare dict values
            if let jsonValue = jsonValue {
                let dataValue = jsonValue.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                let objectValues = (try? NSJSONSerialization.JSONObjectWithData(dataValue, options: NSJSONReadingOptions.MutableContainers)) as? [String:AnyObject]
                let numValue = objectValues!["numValue"] as! Int
                
                XCTAssert(numValue == 13, "number unexpectedly got changed")
            }
            
            jsonValue = ALBNoSQLDB.valueForKey(table: "table12", key: "testKey5")
            // compare dict values
            if let jsonValue = jsonValue {
                let dataValue = jsonValue.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                let objectValues = (try? NSJSONSerialization.JSONObjectWithData(dataValue, options: NSJSONReadingOptions.MutableContainers)) as? [String:AnyObject]
                let numValue = objectValues!["numValue"] as! Int
                
                XCTAssert(numValue == 5, "number was not changed")
                
                
            }
            
            
        } else {
            XCTAssert(false, "unable to create log file")
        }
        
        
    }
    
}