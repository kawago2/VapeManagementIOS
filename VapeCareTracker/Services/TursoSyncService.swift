import Foundation

// MARK: - Turso Sync Service Protocol (Dependency Inversion Principle)
@MainActor
protocol TursoSyncServiceProtocol: AnyObject, ObservableObject {
    var isSyncing: Bool { get set }
    var lastSyncStatus: String? { get set }
    var lastSyncDate: Date? { get set }
    var isConnected: Bool { get }
    
    func updateAuthToken(_ token: String)
    func updateCredentials(url: String, token: String)
    func executeSQL(queries: [String]) async throws -> [[String: Any]]
    func initializeTables() async throws
    func pullDataFromCloud(repository: VapeDataRepositoryProtocol) async throws
    func pushLocalDataToCloud(tanks: [TankSetup], batteries: [BatteryItem], liquids: [LiquidItem]) async throws
    func uploadTank(_ tank: TankSetup) async
    func uploadBattery(_ bat: BatteryItem) async
    func uploadLiquid(_ liq: LiquidItem) async
    func deleteFromCloud(table: String, id: UUID) async
    func syncTwoWay(repository: VapeDataRepositoryProtocol) async throws
    func processPendingQueue() async
}

// MARK: - Turso SQLite Sync Service
@MainActor
final class TursoSyncService: TursoSyncServiceProtocol {
    static let shared = TursoSyncService()
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncStatus: String? = nil
    @Published var lastSyncDate: Date? = nil
    @Published var isConnected: Bool = TursoConfig.isConfigured
    
    private let urlSession: URLSession
    private let offlineQueue: OfflineQueueManagerProtocol
    
    init(
        urlSession: URLSession = .shared,
        offlineQueue: OfflineQueueManagerProtocol = OfflineQueueManager.shared
    ) {
        self.urlSession = urlSession
        self.offlineQueue = offlineQueue
        self.isConnected = TursoConfig.isConfigured
    }
    
    // Update token and connection status reactively
    func updateAuthToken(_ token: String) {
        TursoConfig.authToken = token
        self.isConnected = TursoConfig.isConfigured
        if !self.isConnected {
            self.lastSyncStatus = nil
        }
    }
    
    // Update both database URL and token
    func updateCredentials(url: String, token: String) {
        TursoConfig.databaseURL = url
        TursoConfig.authToken = token
        self.isConnected = TursoConfig.isConfigured
        if !self.isConnected {
            self.lastSyncStatus = nil
        }
    }
    
    // Execute SQL queries via Turso HTTP API v2 pipeline
    func executeSQL(queries: [String]) async throws -> [[String: Any]] {
        guard !TursoConfig.authToken.isEmpty else {
            throw NSError(domain: "TursoSyncService", code: 401, userInfo: [NSLocalizedDescriptionKey: String(localized: "Turso token is empty. Please enter your token in Cloud Settings.")])
        }
        
        let endpoint = URL(string: "\(TursoConfig.databaseURL)/v2/pipeline")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(TursoConfig.authToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestsArray: [[String: Any]] = queries.map { sql in
            return [
                "type": "execute",
                "stmt": ["sql": sql]
            ]
        }
        
        let payload: [String: Any] = ["requests": requestsArray]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "TursoSyncService", code: -1, userInfo: [NSLocalizedDescriptionKey: String(localized: "Failed to connect to Turso.")])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "TursoSyncService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(String(localized: "Turso error")) (\(httpResponse.statusCode)): \(errorMsg)"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let results = json["results"] as? [[String: Any]] {
            return results
        }
        
        return []
    }
    
    // Initialize SQL tables in Turso Cloud SQLite if they do not exist
    func initializeTables() async throws {
        let createTanksSQL = """
        CREATE TABLE IF NOT EXISTS tanks (
            id TEXT PRIMARY KEY,
            tank_name TEXT NOT NULL,
            wire_type TEXT NOT NULL,
            coil_installed_date TEXT NOT NULL,
            cotton_replaced_date TEXT NOT NULL,
            active_liquid_name TEXT NOT NULL,
            coil_max_days INTEGER NOT NULL,
            cotton_max_days INTEGER NOT NULL
        );
        """
        
        let createBatteriesSQL = """
        CREATE TABLE IF NOT EXISTS batteries (
            id TEXT PRIMARY KEY,
            code TEXT NOT NULL,
            brand_and_type TEXT NOT NULL,
            purchased_date TEXT NOT NULL,
            max_days INTEGER NOT NULL,
            notes TEXT
        );
        """
        
        let createLiquidsSQL = """
        CREATE TABLE IF NOT EXISTS liquids (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            opened_date TEXT NOT NULL,
            max_days INTEGER NOT NULL,
            nic_mg TEXT NOT NULL,
            volume_ml TEXT NOT NULL
        );
        """
        
        _ = try await executeSQL(queries: [createTanksSQL, createBatteriesSQL, createLiquidsSQL])
    }
    
    // Helper to extract rows as string dictionaries from Turso pipeline result
    private func parseRows(from resultItem: [String: Any]) -> [[String: String]] {
        guard let response = resultItem["response"] as? [String: Any],
              let result = response["result"] as? [String: Any],
              let cols = result["cols"] as? [[String: Any]],
              let rows = result["rows"] as? [[[String: Any]]] else {
            return []
        }
        
        let colNames = cols.compactMap { $0["name"] as? String }
        var rowDicts: [[String: String]] = []
        
        for row in rows {
            var dict: [String: String] = [:]
            for (idx, cell) in row.enumerated() {
                if idx < colNames.count {
                    let col = colNames[idx]
                    if let val = cell["value"] {
                        dict[col] = String(describing: val)
                    }
                }
            }
            rowDicts.append(dict)
        }
        return rowDicts
    }

    // Pull data from Turso Cloud SQLite to local SwiftData
    func pullDataFromCloud(repository: VapeDataRepositoryProtocol) async throws {
        try await initializeTables()
        
        let results = try await executeSQL(queries: [
            "SELECT id, tank_name, wire_type, coil_installed_date, cotton_replaced_date, active_liquid_name, coil_max_days, cotton_max_days FROM tanks;",
            "SELECT id, code, brand_and_type, purchased_date, max_days, notes FROM batteries;",
            "SELECT id, name, opened_date, max_days, nic_mg, volume_ml FROM liquids;"
        ])
        
        guard results.count >= 3 else { return }
        
        let yyyyMMddFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            return df
        }()
        let isoFormatter = ISO8601DateFormatter()
        let parseDate: (String?) -> Date = { str in
            guard let str = str else { return Date() }
            return yyyyMMddFormatter.date(from: str) ?? isoFormatter.date(from: str) ?? Date()
        }
        
        // 1. Tanks
        let tankRows = parseRows(from: results[0])
        for row in tankRows {
            guard let idStr = row["id"], let id = UUID(uuidString: idStr),
                  let name = row["tank_name"] else { continue }
            let wire = row["wire_type"] ?? ""
            let coilDate = parseDate(row["coil_installed_date"])
            let cottonDate = parseDate(row["cotton_replaced_date"])
            let activeLiq = row["active_liquid_name"] ?? ""
            let coilMax = Int(row["coil_max_days"] ?? "14") ?? 14
            let cottonMax = Int(row["cotton_max_days"] ?? "4") ?? 4
            
            try repository.upsertTank(
                id: id,
                name: name,
                wire: wire,
                coilDate: coilDate,
                cottonDate: cottonDate,
                activeLiquid: activeLiq,
                coilMax: coilMax,
                cottonMax: cottonMax
            )
        }
        
        // 2. Batteries
        let batRows = parseRows(from: results[1])
        for row in batRows {
            guard let idStr = row["id"], let id = UUID(uuidString: idStr),
                  let code = row["code"] else { continue }
            let brand = row["brand_and_type"] ?? ""
            let buyDate = parseDate(row["purchased_date"])
            let maxDays = Int(row["max_days"] ?? "365") ?? 365
            let notes = row["notes"] ?? ""
            
            try repository.upsertBattery(
                id: id,
                code: code,
                brand: brand,
                purchasedDate: buyDate,
                maxDays: maxDays,
                notes: notes
            )
        }
        
        // 3. Liquids
        let liqRows = parseRows(from: results[2])
        for row in liqRows {
            guard let idStr = row["id"], let id = UUID(uuidString: idStr),
                  let name = row["name"] else { continue }
            let openDate = parseDate(row["opened_date"])
            let maxDays = Int(row["max_days"] ?? "90") ?? 90
            let nic = row["nic_mg"] ?? "3mg"
            let vol = row["volume_ml"] ?? "60ml"
            
            try repository.upsertLiquid(
                id: id,
                name: name,
                openedDate: openDate,
                maxDays: maxDays,
                nicMg: nic,
                volumeMl: vol
            )
        }
    }
    
    // Backup data lokal SwiftData ke Turso Cloud SQLite
    func pushLocalDataToCloud(tanks: [TankSetup], batteries: [BatteryItem], liquids: [LiquidItem]) async throws {
        try await initializeTables()
        
        let yyyyMMddFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            return df
        }()
        var queries: [String] = []
        
        // 1. Tanks Upsert
        for tank in tanks {
            let coilDate = yyyyMMddFormatter.string(from: tank.coilInstalledDate)
            let cottonDate = yyyyMMddFormatter.string(from: tank.cottonReplacedDate)
            let safeName = tank.tankName.replacingOccurrences(of: "'", with: "''")
            let safeWire = tank.wireType.replacingOccurrences(of: "'", with: "''")
            let safeLiquid = tank.activeLiquidName.replacingOccurrences(of: "'", with: "''")
            
            let sql = "INSERT OR REPLACE INTO tanks (id, tank_name, wire_type, coil_installed_date, cotton_replaced_date, active_liquid_name, coil_max_days, cotton_max_days) VALUES ('\(tank.id.uuidString)', '\(safeName)', '\(safeWire)', '\(coilDate)', '\(cottonDate)', '\(safeLiquid)', \(tank.coilMaxDays), \(tank.cottonMaxDays));"
            queries.append(sql)
        }
        
        // 2. Batteries Upsert
        for bat in batteries {
            let buyDate = yyyyMMddFormatter.string(from: bat.purchasedDate)
            let safeCode = bat.code.replacingOccurrences(of: "'", with: "''")
            let safeBrand = bat.brandAndType.replacingOccurrences(of: "'", with: "''")
            let safeNotes = bat.notes.replacingOccurrences(of: "'", with: "''")
            
            let sql = "INSERT OR REPLACE INTO batteries (id, code, brand_and_type, purchased_date, max_days, notes) VALUES ('\(bat.id.uuidString)', '\(safeCode)', '\(safeBrand)', '\(buyDate)', \(bat.maxDays), '\(safeNotes)');"
            queries.append(sql)
        }
        
        // 3. Liquids Upsert
        for liq in liquids {
            let openDate = yyyyMMddFormatter.string(from: liq.openedDate)
            let safeName = liq.name.replacingOccurrences(of: "'", with: "''")
            let safeNic = liq.nicMg.replacingOccurrences(of: "'", with: "''")
            let safeVol = liq.volumeMl.replacingOccurrences(of: "'", with: "''")
            
            let sql = "INSERT OR REPLACE INTO liquids (id, name, opened_date, max_days, nic_mg, volume_ml) VALUES ('\(liq.id.uuidString)', '\(safeName)', '\(openDate)', \(liq.maxDays), '\(safeNic)', '\(safeVol)');"
            queries.append(sql)
        }
        
        if !queries.isEmpty {
            _ = try await executeSQL(queries: queries)
        }
    }
    
    // Upload single tank change / addition to cloud
    func uploadTank(_ tank: TankSetup) async {
        guard isConnected else { return }
        let yyyyMMddFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            return df
        }()
        let coilDate = yyyyMMddFormatter.string(from: tank.coilInstalledDate)
        let cottonDate = yyyyMMddFormatter.string(from: tank.cottonReplacedDate)
        let safeName = tank.tankName.replacingOccurrences(of: "'", with: "''")
        let safeWire = tank.wireType.replacingOccurrences(of: "'", with: "''")
        let safeLiquid = tank.activeLiquidName.replacingOccurrences(of: "'", with: "''")
        
        let sql = "INSERT OR REPLACE INTO tanks (id, tank_name, wire_type, coil_installed_date, cotton_replaced_date, active_liquid_name, coil_max_days, cotton_max_days) VALUES ('\(tank.id.uuidString)', '\(safeName)', '\(safeWire)', '\(coilDate)', '\(cottonDate)', '\(safeLiquid)', \(tank.coilMaxDays), \(tank.cottonMaxDays));"
        
        do {
            _ = try await executeSQL(queries: [sql])
        } catch {
            print("Failed to upload tank to cloud, queuing: \(error.localizedDescription)")
            offlineQueue.enqueue(query: sql, description: "Upload tank: \(tank.tankName)")
        }
    }
    
    // Upload single battery change / addition to cloud
    func uploadBattery(_ bat: BatteryItem) async {
        let yyyyMMddFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            return df
        }()
        let buyDate = yyyyMMddFormatter.string(from: bat.purchasedDate)
        let safeCode = bat.code.replacingOccurrences(of: "'", with: "''")
        let safeBrand = bat.brandAndType.replacingOccurrences(of: "'", with: "''")
        let safeNotes = bat.notes.replacingOccurrences(of: "'", with: "''")
        
        let sql = "INSERT OR REPLACE INTO batteries (id, code, brand_and_type, purchased_date, max_days, notes) VALUES ('\(bat.id.uuidString)', '\(safeCode)', '\(safeBrand)', '\(buyDate)', \(bat.maxDays), '\(safeNotes)');"
        
        guard isConnected else {
            offlineQueue.enqueue(query: sql, description: "Upload battery: \(bat.code)")
            return
        }
        
        do {
            _ = try await executeSQL(queries: [sql])
        } catch {
            print("Failed to upload battery to cloud, queuing: \(error.localizedDescription)")
            offlineQueue.enqueue(query: sql, description: "Upload battery: \(bat.code)")
        }
    }
    
    // Upload single liquid change / addition to cloud
    func uploadLiquid(_ liq: LiquidItem) async {
        let yyyyMMddFormatter: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            return df
        }()
        let openDate = yyyyMMddFormatter.string(from: liq.openedDate)
        let safeName = liq.name.replacingOccurrences(of: "'", with: "''")
        let safeNic = liq.nicMg.replacingOccurrences(of: "'", with: "''")
        let safeVol = liq.volumeMl.replacingOccurrences(of: "'", with: "''")
        
        let sql = "INSERT OR REPLACE INTO liquids (id, name, opened_date, max_days, nic_mg, volume_ml) VALUES ('\(liq.id.uuidString)', '\(safeName)', '\(openDate)', \(liq.maxDays), '\(safeNic)', '\(safeVol)');"
        
        guard isConnected else {
            offlineQueue.enqueue(query: sql, description: "Upload liquid: \(liq.name)")
            return
        }
        
        do {
            _ = try await executeSQL(queries: [sql])
        } catch {
            print("Failed to upload liquid to cloud, queuing: \(error.localizedDescription)")
            offlineQueue.enqueue(query: sql, description: "Upload liquid: \(liq.name)")
        }
    }
    
    // Delete items from cloud
    func deleteFromCloud(table: String, id: UUID) async {
        let sql = "DELETE FROM \(table) WHERE id = '\(id.uuidString)';"
        
        guard isConnected else {
            offlineQueue.enqueue(query: sql, description: "Delete \(table): \(id.uuidString)")
            return
        }
        
        do {
            _ = try await executeSQL(queries: [sql])
        } catch {
            print("Failed to delete from \(table), queuing: \(error.localizedDescription)")
            offlineQueue.enqueue(query: sql, description: "Delete \(table): \(id.uuidString)")
        }
    }
    
    // Two-Way Sync: Pull changes from Cloud then Push local data
    func syncTwoWay(repository: VapeDataRepositoryProtocol) async throws {
        self.isSyncing = true
        defer { self.isSyncing = false }
        
        // Step 1: Flush pending offline queue first if any
        await processPendingQueue()
        
        // Step 2: Pull latest data from Cloud to local
        try await pullDataFromCloud(repository: repository)
        
        // Step 3: Push current local data to Cloud
        let currentTanks = try repository.fetchTanks()
        let currentBatteries = try repository.fetchBatteries()
        let currentLiquids = try repository.fetchLiquids()
        
        try await pushLocalDataToCloud(
            tanks: currentTanks,
            batteries: currentBatteries,
            liquids: currentLiquids
        )
        
        self.lastSyncDate = Date()
        self.lastSyncStatus = String(localized: "Two-way sync completed successfully!")
    }
    
    // Process and flush offline queue items when reconnected
    func processPendingQueue() async {
        let pending = offlineQueue.getPendingQueue()
        guard !pending.isEmpty, isConnected else { return }
        
        var succeededIds: [UUID] = []
        for item in pending {
            do {
                _ = try await executeSQL(queries: [item.query])
                succeededIds.append(item.id)
            } catch {
                print("Failed to replay queued query: \(item.description) - \(error.localizedDescription)")
                break // Stop on error to preserve FIFO ordering
            }
        }
        
        for id in succeededIds {
            offlineQueue.remove(id: id)
        }
    }
}
