import Foundation

struct Tree {
    let uuid: String
    let species: String
    let height: Int

    init(species: String, height: Int) {
        self.init(uuid: NSUUID().UUIDString, species: species, height: height)
    }

    init(uuid: String, species: String, height: Int) {
        self.uuid = uuid
        self.species = species
        self.height = height
    }
}
