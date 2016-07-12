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

    deinit {
        dispose()
    }

    // MARK: Public methods

    public func dispose() {
        guard hasBeenDisposed.ensureFalseThenSetTrue() else { return }
        action?()
        action = nil
    }
}

public class AssignableDisposable: Disposable {
    // MARK: Public properties

    public private(set) var disposed: Bool = false

    public var disposable: Disposable? {
        get {
            OSSpinLockLock(&lock)
            defer { OSSpinLockUnlock(&lock) }
            return _disposable ?? NoActionDisposable()
        }
        set {
            OSSpinLockLock(&lock)
            defer { OSSpinLockUnlock(&lock) }

            guard !disposed else {
                newValue?.dispose()
                _disposable = nil
                return
            }

            _disposable = newValue
        }

    }

    // MARK: Private properties

    private var lock = OSSpinLock()
    private var _disposable: Disposable? = nil

    // MARK: Object lifecycle

    public init() {

    }

    deinit {
        dispose()
    }

    // MARK: Public methods

    public func dispose() {
        OSSpinLockLock(&lock)
        defer { OSSpinLockUnlock(&lock) }

        guard !disposed else {
            _disposable = nil
            return
        }

        _disposable?.dispose()
        disposed = true
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
