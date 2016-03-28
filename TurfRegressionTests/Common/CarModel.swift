import Foundation

/// A very simple model
struct CarModel {
    let uuid: String
    let manufacturer: String
    let name: String
    let doors: Int

    init(manufacturer: String, name: String, doors: Int) {
        self.init(uuid: NSUUID().UUIDString, manufacturer: manufacturer, name: name, doors: doors)
    }

    init(uuid: String, manufacturer: String, name: String, doors: Int) {
        self.uuid = uuid
        self.manufacturer = manufacturer
        self.name = name
        self.doors = doors
    }

}