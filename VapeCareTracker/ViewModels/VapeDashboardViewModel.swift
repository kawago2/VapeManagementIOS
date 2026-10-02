import Foundation
import SwiftUI
import SwiftData

@MainActor
final class VapeDashboardViewModel: ObservableObject {
    private let repository: VapeDataRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    let syncService: any TursoSyncServiceProtocol
    
    @Published var tanks: [TankSetup] = []
    @Published var batteries: [BatteryItem] = []
    @Published var liquids: [LiquidItem] = []
    
    // Refresh & Toast feedback state
    @Published var isRefreshing: Bool = false
    @Published var toastMessage: String? = nil
    @Published var isToastError: Bool = false
    
    // Status metrics
    var overdueCoilCount: Int {
        tanks.filter { $0.coilHealthStatus.isOverdue }.count
    }
    
    var overdueCottonCount: Int {
        tanks.filter { $0.cottonHealthStatus.isOverdue }.count
    }
    
    init(
        repository: VapeDataRepositoryProtocol,
        notificationService: NotificationServiceProtocol? = nil,
        syncService: (any TursoSyncServiceProtocol)? = nil
    ) {
        self.repository = repository
        self.notificationService = notificationService ?? NotificationManager.shared
        self.syncService = syncService ?? TursoSyncService.shared
    }
    
    func onAppear() async {
        loadAllData()
        _ = await notificationService.requestAuthorization()
        notificationService.scheduleReminders(for: tanks)
        
        // Alur utama: Ambil (pull) data dari DB terlebih dahulu
        if TursoConfig.isConfigured {
            await pullFromCloud(showToast: false)
        }
    }
    
    // 1. Get dari DB dengan feedback Toast & Animasi
    func pullFromCloud(showToast: Bool = true) async {
        let startTime = Date()
        withAnimation(.easeInOut(duration: 0.2)) {
            isRefreshing = true
        }
        syncService.isSyncing = true
        
        defer {
            withAnimation(.easeInOut(duration: 0.2)) {
                isRefreshing = false
            }
            syncService.isSyncing = false
        }
        
        guard TursoConfig.isConfigured else {
            if showToast {
                // Beri sedikit jeda agar icon sempat berputar
                try? await Task.sleep(nanoseconds: 400_000_000)
                showToastNotification("Database URL atau Auth Token belum disetel", isError: true)
            }
            return
        }
        
        do {
            try await syncService.pullDataFromCloud(repository: repository)
            loadAllData()
            notificationService.scheduleReminders(for: tanks)
            syncService.lastSyncDate = Date()
            syncService.lastSyncStatus = "Data berhasil dimuat dari cloud!"
            
            // Pastikan animasi berputar minimal 500ms agar terasa feedbacknya oleh user
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < 0.5 {
                let remainingNs = UInt64((0.5 - elapsed) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: remainingNs)
            }
            
            if showToast {
                showToastNotification("Sinkronisasi cloud berhasil!")
            }
        } catch {
            let errorText = error.localizedDescription
            print("Cloud pull error: \(errorText)")
            syncService.lastSyncStatus = "Gagal memuat: \(errorText)"
            
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < 0.5 {
                let remainingNs = UInt64((0.5 - elapsed) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: remainingNs)
            }
            
            if showToast {
                showToastNotification("Gagal refresh: \(errorText)", isError: true)
            }
        }
    }
    
    func syncWithCloud() async {
        await pullFromCloud(showToast: true)
    }
    
    private func showToastNotification(_ message: String, isError: Bool = false) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            self.toastMessage = message
            self.isToastError = isError
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                if self.toastMessage == message {
                    self.toastMessage = nil
                }
            }
        }
    }
    
    func loadAllData() {
        do {
            self.tanks = try repository.fetchTanks()
            self.batteries = try repository.fetchBatteries()
            self.liquids = try repository.fetchLiquids()
        } catch {
            print("Error fetching data: \(error.localizedDescription)")
        }
    }
    
    // 2. Simpan dan Tambah Data (Enkapsulasi OOP & DIP)
    func saveTank(
        existing: TankSetup?,
        tankName: String,
        wireType: String,
        coilInstalledDate: Date,
        cottonReplacedDate: Date,
        activeLiquidName: String,
        coilMaxDays: Int,
        cottonMaxDays: Int
    ) {
        let savedTank: TankSetup
        if let existing = existing {
            existing.tankName = tankName
            existing.wireType = wireType
            existing.coilInstalledDate = coilInstalledDate
            existing.cottonReplacedDate = cottonReplacedDate
            existing.activeLiquidName = activeLiquidName
            existing.coilMaxDays = coilMaxDays
            existing.cottonMaxDays = cottonMaxDays
            savedTank = existing
        } else {
            let newTank = TankSetup(
                tankName: tankName,
                wireType: wireType,
                coilInstalledDate: coilInstalledDate,
                cottonReplacedDate: cottonReplacedDate,
                activeLiquidName: activeLiquidName,
                coilMaxDays: coilMaxDays,
                cottonMaxDays: cottonMaxDays
            )
            repository.insert(newTank)
            savedTank = newTank
        }
        saveAndSyncNotifications()
        Task {
            await syncService.uploadTank(savedTank)
        }
    }
    
    func saveBattery(
        existing: BatteryItem?,
        code: String,
        brandAndType: String,
        purchasedDate: Date,
        maxDays: Int,
        notes: String
    ) {
        let savedBattery: BatteryItem
        if let existing = existing {
            existing.code = code
            existing.brandAndType = brandAndType
            existing.purchasedDate = purchasedDate
            existing.maxDays = maxDays
            existing.notes = notes
            savedBattery = existing
        } else {
            let newBattery = BatteryItem(
                code: code,
                brandAndType: brandAndType,
                purchasedDate: purchasedDate,
                maxDays: maxDays,
                notes: notes
            )
            repository.insert(newBattery)
            savedBattery = newBattery
        }
        saveDataOnly()
        Task {
            await syncService.uploadBattery(savedBattery)
        }
    }
    
    func saveLiquid(
        existing: LiquidItem?,
        name: String,
        openedDate: Date,
        maxDays: Int,
        nicMg: String,
        volumeMl: String
    ) {
        let savedLiquid: LiquidItem
        if let existing = existing {
            existing.name = name
            existing.openedDate = openedDate
            existing.maxDays = maxDays
            existing.nicMg = nicMg
            existing.volumeMl = volumeMl
            savedLiquid = existing
        } else {
            let newLiquid = LiquidItem(
                name: name,
                openedDate: openedDate,
                maxDays: maxDays,
                nicMg: nicMg,
                volumeMl: volumeMl
            )
            repository.insert(newLiquid)
            savedLiquid = newLiquid
        }
        saveDataOnly()
        Task {
            await syncService.uploadLiquid(savedLiquid)
        }
    }
    
    // Quick Actions
    func quickResetCotton(for tank: TankSetup) {
        tank.cottonReplacedDate = Date()
        saveAndSyncNotifications()
        Task {
            await syncService.uploadTank(tank)
        }
    }
    
    func quickResetCoil(for tank: TankSetup) {
        tank.coilInstalledDate = Date()
        saveAndSyncNotifications()
        Task {
            await syncService.uploadTank(tank)
        }
    }
    
    func updateActiveLiquid(for tank: TankSetup, liquidName: String) {
        tank.activeLiquidName = liquidName
        saveDataOnly()
        Task {
            await syncService.uploadTank(tank)
        }
    }
    
    // 3. Penghapusan data -> Hapus di DB
    func deleteTank(_ tank: TankSetup) {
        let id = tank.id
        do {
            try repository.delete(tank)
            loadAllData()
            notificationService.scheduleReminders(for: tanks)
            Task {
                await syncService.deleteFromCloud(table: "tanks", id: id)
            }
        } catch {
            print("Error deleting tank: \(error.localizedDescription)")
        }
    }
    
    func deleteBattery(_ battery: BatteryItem) {
        let id = battery.id
        do {
            try repository.delete(battery)
            loadAllData()
            Task {
                await syncService.deleteFromCloud(table: "batteries", id: id)
            }
        } catch {
            print("Error deleting battery: \(error.localizedDescription)")
        }
    }
    
    func deleteLiquid(_ liquid: LiquidItem) {
        let id = liquid.id
        do {
            try repository.delete(liquid)
            loadAllData()
            Task {
                await syncService.deleteFromCloud(table: "liquids", id: id)
            }
        } catch {
            print("Error deleting liquid: \(error.localizedDescription)")
        }
    }
    
    private func saveAndSyncNotifications() {
        do {
            try repository.save()
            loadAllData()
            notificationService.scheduleReminders(for: tanks)
        } catch {
            print("Error saving: \(error.localizedDescription)")
        }
    }
    
    private func saveDataOnly() {
        do {
            try repository.save()
            loadAllData()
        } catch {
            print("Error saving data: \(error.localizedDescription)")
        }
    }
}
