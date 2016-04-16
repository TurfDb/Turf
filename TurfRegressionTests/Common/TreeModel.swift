import Foundation

struct Tree {
    let uuid: String
    let species: String
    let height: Int
    let longitude: Double
    let latitude: Double

    init(species: String, height: Int, longitude: Double, latitude: Double) {
        self.init(uuid: NSUUID().UUIDString, species: species, height: height, longitude: longitude, latitude: latitude)
    }

    init(uuid: String, species: String, height: Int, longitude: Double, latitude: Double) {
        self.uuid = uuid
        self.species = species
        self.height = height
        self.longitude = longitude
        self.latitude = latitude
    }
}
