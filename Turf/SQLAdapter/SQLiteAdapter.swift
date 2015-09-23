//
//  SQLiteAdapter.swift
//  Turf
//
//  Created by Jordan Hamill on 23/09/2015.
//  Copyright © 2015 JordanHamill. All rights reserved.
//

import Foundation
import SQLite

private let Prefix = "_turf"

internal class SQLiteAdapter: NSObject {
    let db: SQLite.Connection

    private let queryCache: SQLStatementCache
    private let metadataTable = MetadataTable()
    private let extensionsTable = ExtensionsTable()
    private let runtimeOperationsTable = RuntimeOperationsTable()

    init(db: SQLite.Connection) {
        self.db = db
        self.queryCache = SQLStatementCache()
    }

    func beginTransaction() throws {
        let q = queryCache.query(key: "begin transaction", query: db.prepare("BEGIN TRANSACTION;"))
        try q.run()
    }

    func commitTransaction() throws {
        let q = queryCache.query(key: "commit transaction", query: db.prepare("COMMIT TRANSACTION;"))
        try q.run()
    }

    func rollbackTransaction() throws {
        let q = queryCache.query(key: "rollback transaction", query: db.prepare("ROLLBACK TRANSACTION;"))
        try q.run()
    }

    func isExistingTurfDatabase() -> Bool {
        let schemaVersion: Int
        if let metadataRow = db.pluck(metadataTable.T) {
            schemaVersion = metadataRow.get(metadataTable.schema_version)
        } else {
            schemaVersion = 0
        }
        return schemaVersion > 0
    }

    func initializeTurfDatabase() throws {
        if !isExistingTurfDatabase() {
            try createMetadataTable()
            try createExtensionsTable()
            try createRuntimeOperationsTable()
        }
    }

    // MARK: Private methods

    private func createMetadataTable() throws {
        try db.run(metadataTable.T.create { t in
            t.column(metadataTable.schema_version, defaultValue: TurfSchemaVersion)
        })
    }

    private func createExtensionsTable() throws {
        try db.run(extensionsTable.T.create { t in
            t.primaryKey(extensionsTable.uuid)
            t.unique(extensionsTable.name)
            t.column(extensionsTable.version, defaultValue: 0)
            t.column(extensionsTable.data)
            //Future proofing to allow migration handling in case core extension internals may change
            t.column(extensionsTable.turfExtensionVersion, defaultValue: 0)
        })
    }

    private func createRuntimeOperationsTable() throws {
        try db.run(runtimeOperationsTable.T.create { t in
            t.column(runtimeOperationsTable.snapshot, defaultValue: 0)
        })
    }

    private struct MetadataTable {
        let T = Table("\(Prefix)_metadata")
        let schema_version = Expression<Int>("schema_version")
    }

    private struct ExtensionsTable {
        let T = Table("\(Prefix)_extensions")
        let uuid = Expression<String>("uuid")
        let name = Expression<String>("name")
        let version = Expression<Int>("version")
        let data = Expression<NSData>("data")
        let turfExtensionVersion = Expression<Int>("turf_version")
    }

    private struct RuntimeOperationsTable {
        let T = Table("\(Prefix)_runtime")
        let snapshot = Expression<Int64>("snapshot")
    }
}
