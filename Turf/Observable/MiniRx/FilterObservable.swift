import Foundation

extension Observable {
    public func filter(_ filter: @escaping (Value) -> Bool) -> Observable<Value> {
        return self.flatMap { (value)  in
            if filter(value) {
                return Observable.just(value)
            } else {
                return Observable.never()
            }
        }
    }
}
