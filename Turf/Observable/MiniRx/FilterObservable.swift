import Foundation

extension Observable {
    public func filter(filter: (Value) -> Bool) -> Observable<Value> {
        return self.flatMap { (value)  in
            if filter(value) {
                return Observable.just(value)
            } else {
                return Observable.never()
            }
        }
    }
}
