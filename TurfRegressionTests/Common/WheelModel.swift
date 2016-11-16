import Foundation

/// A very simple class model
struct WheelModel {
    let uuid: String
    let manufacturer: String
    let size: Double

    init(manufacturer: String, size: Double) {
        self.init(uuid: UUID().uuidString, manufacturer: manufacturer, size: size)
    }

    init(uuid: String, manufacturer: String, size: Double) {
        self.uuid = uuid
        self.manufacturer = manufacturer
        self.size = size
    }
}
