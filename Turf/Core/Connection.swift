//
//  Connection.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation

public class Connection {

    public private(set) unowned var database: Database
    public var cacheEnabled: Bool
    public var cacheLimit: UInt

    public private(set) var snapshot: UInt
    public private(set) var hasOpenedEndedReadTransaction: Bool

    internal init(database: Database) {
        self.database = database
        self.cacheEnabled = true
        self.cacheLimit = 200

        self.snapshot = 0
        self.hasOpenedEndedReadTransaction = false
    }

    public func readTransaction(operations: (ReadTransaction) -> Void) {

    }

    public func readWriteTransaction(operations: (ReadWriteTransaction) -> Void) {
        
    }

}
