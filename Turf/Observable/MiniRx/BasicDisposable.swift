import Foundation

extension Disposable {
    public static func noAction() -> Disposable {
        return NoActionDisposable()
    }
}

class NoActionDisposable: Disposable {
    // MARK: Internal properties

    var disposed: Bool { return hasBeenDisposed == true }

    // MARK: Private properties

    private let hasBeenDisposed: AtomicBool = false

    // MARK: Object lifecycle

    private init() { }

    // MARK: Public methods

    func dispose() {
        guard hasBeenDisposed.ensureFalseThenSetTrue() else { return }
    }
}


public class BasicDisposable: Disposable {
    // MARK: Public properties

    public var disposed: Bool { return hasBeenDisposed == true }

    // MARK: Private properties

    private let hasBeenDisposed: AtomicBool = false
    private var action: (() -> Void)?

    // MARK: Object lifecycle

    public init(_ action: () -> Void) {
        self.action = action
    }

    // MARK: Public methods

    public func dispose() {
        guard hasBeenDisposed.ensureFalseThenSetTrue() else { return }
        action?()
        action = nil
    }
}


internal class AtomicBool: BooleanLiteralConvertible {
    private var rawValue: Int32 = 0

    required init(booleanLiteral value: Bool) {
        self.rawValue = value ? 1 : 0
    }

    func ensureFalseThenSetTrue() -> Bool {
        if OSAtomicCompareAndSwap32(0, 1, &rawValue) {
            return true
        }
        return false
    }
}

func == (lhs: AtomicBool, rhs: Bool) -> Bool {
    return lhs.rawValue == (rhs ? 1: 0)
}
