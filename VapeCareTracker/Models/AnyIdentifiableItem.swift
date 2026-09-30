import Foundation

struct AnyIdentifiableItem: Identifiable {
    let id: UUID
    let title: String
    let rawType: ItemType
    
    enum ItemType {
        case tank(TankSetup)
        case battery(BatteryItem)
        case liquid(LiquidItem)
    }
}
