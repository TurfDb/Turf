//
//  Database.swift
//  Turf
//
//  Created by Jordan Hamill on 20/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation

public class Database {

    private lazy var connectionPool: ConnectionPool = {
        [unowned self] in
        return ConnectionPool(database: self, maximumPoolSize: 1)
        }()

    ///
    /// Create and register a new database with the given name.
    /// :param: name This could be a path to the database file.
    ///
    public init?(name: String) throws {
        
    }

    ///
    /// Create a new connection to the database.
    /// Connections have their own item cache which can be configured.
    /// :returns: A new connection if available.
    ///
    public func newConnection() -> Connection? {
        return connectionPool.newConnection()
    }

    ///
    /// This should forcefully shutdown all connections to the database.
    /// :returns: True if it succeeds.
    ///
    public func closeAllConnections() -> Bool {
        return false
    }

    ///
    /// Add a database extension.
    /// :param: ext An extension which could, for instance, add secondary indexing.
    /// :returns: True if the extension is successfully registered.
    ///
    public func addExtension(ext: Extension) -> Bool {
        return false
    }

    ///
    /// Remove an already registered extension.
    /// :param: ext Extension to remove.
    /// :returns: True if the extension is successfully unregistered or was never registered.
    ///
    public func removeExtension(ext: Extension) -> Bool {
        return false
    }
}
