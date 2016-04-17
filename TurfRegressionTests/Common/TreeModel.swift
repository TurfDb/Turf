import Foundation

struct Tree {
    let uuid: String
    let type: String
    let species: String
    let height: Int
    let age: TreeAge

    init(type: String, species: String, height: Int, age: TreeAge) {
        self.init(uuid: NSUUID().UUIDString, type: type, species: species, height: height, age: age)
    }

    init(uuid: String, type: String, species: String, height: Int, age: TreeAge) {
        self.uuid = uuid
        self.type = type
        self.species = species
        self.height = height
        self.age = age
    }
}

enum TreeAge: Int {
    case Juvenile
    case Young
    case Mature
    case FullyMature
}
