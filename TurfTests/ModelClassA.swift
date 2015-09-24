import Foundation

final class ModelClassA {
    let const1: Int32
    let const2: Int64
    let const3: String
    let const4: Bool

    var var1: Int32
    var var2: Int64
    var name: String
    var var4: Bool

    init() {
        const1 = rand()
        const2 = Int64(rand())
        const3 = NSUUID().UUIDString
        const4 = Float(Float(arc4random()) / Float(UINT32_MAX)) > 0.5

        var1 = rand()
        var2 = Int64(rand())
        name = NSUUID().UUIDString
        var4 = Float(Float(arc4random()) / Float(UINT32_MAX)) > 0.5
    }

    private init(const1: Int32, const2: Int64, const3: String, const4: Bool,
        var1: Int32, var2: Int64, name: String, var4: Bool) {
            self.const1 = const1
            self.const2 = const2
            self.const3 = const3
            self.const4 = const4
            self.var1 = var1
            self.var2 = var2
            self.name = name
            self.var4 = var4
    }

}

//extension ModelClassA: Serializable {
//    func serialize(serializer: Serializer) {
//        serializer["const1"] <- const1
//        serializer["const2"] <- const2
//        serializer["const3"] <- const3
//        serializer["const4"] <- const4
//
//        serializer["var1"] <- var1
//        serializer["var2"] <- var2
//        serializer["name"] <- name
//        serializer["var4"] <- var4
//    }
//
//    static func deserialize(deserializer: Serializer) -> ModelClassA? {
//        return ModelClassA(
//            const1: <-deserializer["const1"],
//            const2: <-deserializer["const2"],
//            const3: <-deserializer["const3"],
//            const4: <-deserializer["const4"],
//            var1:   <-deserializer["var1"],
//            var2:   <-deserializer["var2"],
//            name:   <-deserializer["name"],
//            var4:   <-deserializer["var4"])
//    }
//
//    private convenience init?(const1: Int32?, const2: Int64?, const3: String?, const4: Bool?,
//        var1: Int32?, var2: Int64?, name: String?, var4: Bool?) {
//            if let const1 = const1,
//                const2 = const2,
//                const3 = const3,
//                const4 = const4,
//                var1 = var1,
//                var2 = var2,
//                name = name,
//                var4 = var4 {
//
//                    self.init(
//                        const1: const1,
//                        const2: const2,
//                        const3: const3,
//                        const4: const4,
//                        var1: var1,
//                        var2: var2,
//                        name: name,
//                        var4: var4)
//            } else {
//                return nil
//            }
//    }
//}