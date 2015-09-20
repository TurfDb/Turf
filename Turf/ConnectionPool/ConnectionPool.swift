//
//  ConnectionPool.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation

class ConnectionPool {
    let maximumPoolSize: Int

    private unowned let database: Database

    private class PooledConnection {
        let connection: Connection
        var timestamp: NSDate
        var inUse: Bool

        init(connection: Connection) {
            self.connection = connection
            self.timestamp = NSDate()
            self.inUse = true
        }
    }

    private var connections: [PooledConnection]

    init(database: Database, maximumPoolSize: UInt) {
        self.database = database
        self.maximumPoolSize = Int(maximumPoolSize)
        self.connections = []
        self.connections.reserveCapacity(self.maximumPoolSize)
    }

    func newConnection() -> Connection? {
        var unusedConnection = connections.filter { !$0.inUse }.first
        if let unusedConnection = unusedConnection {
            unusedConnection.inUse = true
            unusedConnection.timestamp = NSDate()
        } else {
            unusedConnection = PooledConnection(connection: Connection(database: database))
            if connections.count < maximumPoolSize {
                connections.append(unusedConnection!)
            }
        }

        return unusedConnection?.connection
    }

    func freeConnection(connection: Connection) {
        if let pooledConnection = self.connections.filter({ $0.connection === connection }).first {
            pooledConnection.inUse = false
            pooledConnection.timestamp = NSDate()
        }
    }
}
