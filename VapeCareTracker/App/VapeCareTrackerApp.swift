import SwiftUI
import SwiftData

@main
struct VapeCareTrackerApp: App {
    let container: ModelContainer
    let repository: VapeDataRepository
    
    init() {
        do {
            let schema = Schema([
                TankSetup.self,
                BatteryItem.self,
                LiquidItem.self
            ])
            
            let fileManager = FileManager.default
            let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let storeURL = documentDirectory.appendingPathComponent("vapecare_v2_storage.store")
            
            let modelConfiguration = ModelConfiguration(
                "VapeCareSystemModel",
                schema: schema,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            
            let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.container = modelContainer
            self.repository = VapeDataRepository(context: modelContainer.mainContext)
        } catch {
            fatalError("Gagal menginisialisasi SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            VapeManagementDashboardView(repository: repository)
        }
        .modelContainer(container)
    }
}
