import Turf

final class TestDatabase {
    let database: Database<Collections>
    let collections: Collections
    let connection1: Connection<Collections>
    let connection2: Connection<Collections>
    fileprivate(set) var observingConnection: ObservingConnection<Collections>!

    init(databasePath: String) throws {
        self.collections = Collections()
        self.database = try Database(path: databasePath, collections: collections)
        self.connection1 = try self.database.newConnection()
        self.connection2 = try self.database.newConnection()
        self.observingConnection = try self.database.newObservingConnection()
    }

    deinit {
        //Work around to control the deinit sequence.
        // Observing connection needs shutdown before `database` is dealloc'd
        observingConnection = nil
    }
}
