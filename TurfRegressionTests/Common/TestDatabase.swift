import Turf

final class TestDatabase {
    let database: Database
    let collections: Collections
    let connection1: Connection
    let connection2: Connection
    let observingConnection: ObservingConnection

    init(databasePath: String) throws {
        self.collections = Collections()
        self.database = try Database(path: databasePath, collections: collections)
        self.connection1 = try self.database.newConnection()
        self.connection2 = try self.database.newConnection()
        self.observingConnection = try self.database.newObservingConnection()
    }
}
