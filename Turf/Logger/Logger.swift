open class Logger {
    open static var stdoutEnabled = false

    static func log(warning items: Any..., separator: String = ", ", terminator: String = "\n", file: String = #file, function: String = #function) {
        guard stdoutEnabled else { return }

        var mutableItems = items
        mutableItems.insert("Turf [Warning] in \(function)", at: 0)
        print(mutableItems, separator: separator, terminator: terminator)
    }

    static func log(error items: Any..., separator: String = ", ", terminator: String = "\n", file: String = #file, function: String = #function) {
        guard stdoutEnabled else { return }

        var mutableItems = items
        mutableItems.insert("Turf [Error] in \(function)", at: 0)
        print(mutableItems, separator: separator, terminator: terminator)
    }
}
