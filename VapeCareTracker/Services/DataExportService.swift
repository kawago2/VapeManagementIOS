import Foundation
import UniformTypeIdentifiers

// MARK: - Export Data Structure
struct VapeCareExportPayload: Codable {
    let exportedAt: Date
    let appVersion: String
    let tanks: [TankExportItem]
    let batteries: [BatteryExportItem]
    let liquids: [LiquidExportItem]
    let maintenanceLogs: [MaintenanceLogExportItem]
    
    struct TankExportItem: Codable {
        let id: String
        let tankName: String
        let wireType: String
        let coilInstalledDate: Date
        let cottonReplacedDate: Date
        let activeLiquidName: String
        let coilMaxDays: Int
        let cottonMaxDays: Int
    }
    
    struct BatteryExportItem: Codable {
        let id: String
        let code: String
        let brandAndType: String
        let purchasedDate: Date
        let maxDays: Int
        let notes: String
    }
    
    struct LiquidExportItem: Codable {
        let id: String
        let name: String
        let openedDate: Date
        let maxDays: Int
        let nicMg: String
        let volumeMl: String
    }
    
    struct MaintenanceLogExportItem: Codable {
        let id: String
        let tankId: String
        let tankName: String
        let actionType: String
        let date: Date
        let notes: String
    }
}

// MARK: - Data Export Service Protocol
protocol DataExportServiceProtocol {
    func generateJSONExport(
        tanks: [TankSetup],
        batteries: [BatteryItem],
        liquids: [LiquidItem],
        logs: [MaintenanceLog]
    ) throws -> URL
    
    func generateCSVExport(
        tanks: [TankSetup],
        batteries: [BatteryItem],
        liquids: [LiquidItem],
        logs: [MaintenanceLog]
    ) throws -> URL
}

// MARK: - Implementation
final class DataExportService: DataExportServiceProtocol {
    static let shared = DataExportService()
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        df.locale = Locale(identifier: "id_ID")
        return df
    }()
    
    func generateJSONExport(
        tanks: [TankSetup],
        batteries: [BatteryItem],
        liquids: [LiquidItem],
        logs: [MaintenanceLog]
    ) throws -> URL {
        let payload = VapeCareExportPayload(
            exportedAt: Date(),
            appVersion: "1.0.0",
            tanks: tanks.map {
                .init(
                    id: $0.id.uuidString,
                    tankName: $0.tankName,
                    wireType: $0.wireType,
                    coilInstalledDate: $0.coilInstalledDate,
                    cottonReplacedDate: $0.cottonReplacedDate,
                    activeLiquidName: $0.activeLiquidName,
                    coilMaxDays: $0.coilMaxDays,
                    cottonMaxDays: $0.cottonMaxDays
                )
            },
            batteries: batteries.map {
                .init(
                    id: $0.id.uuidString,
                    code: $0.code,
                    brandAndType: $0.brandAndType,
                    purchasedDate: $0.purchasedDate,
                    maxDays: $0.maxDays,
                    notes: $0.notes
                )
            },
            liquids: liquids.map {
                .init(
                    id: $0.id.uuidString,
                    name: $0.name,
                    openedDate: $0.openedDate,
                    maxDays: $0.maxDays,
                    nicMg: $0.nicMg,
                    volumeMl: $0.volumeMl
                )
            },
            maintenanceLogs: logs.map {
                .init(
                    id: $0.id.uuidString,
                    tankId: $0.tankId.uuidString,
                    tankName: $0.tankName,
                    actionType: $0.actionType,
                    date: $0.date,
                    notes: $0.notes
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(payload)
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("VapeCare_Backup_\(dateStamp()).json")
        try data.write(to: fileURL)
        return fileURL
    }
    
    func generateCSVExport(
        tanks: [TankSetup],
        batteries: [BatteryItem],
        liquids: [LiquidItem],
        logs: [MaintenanceLog]
    ) throws -> URL {
        var csv = "=== TANKS & COILS ===\n"
        csv += "Nama Tank,Kawat/Coil,Tgl Pasang Coil,Tgl Ganti Kapas,Liquid Aktif,Maks Hari Coil,Maks Hari Kapas\n"
        for t in tanks {
            let row = [
                escapeCSV(t.tankName),
                escapeCSV(t.wireType),
                dateFormatter.string(from: t.coilInstalledDate),
                dateFormatter.string(from: t.cottonReplacedDate),
                escapeCSV(t.activeLiquidName),
                "\(t.coilMaxDays)",
                "\(t.cottonMaxDays)"
            ].joined(separator: ",")
            csv += "\(row)\n"
        }
        
        csv += "\n=== BATTERIES ===\n"
        csv += "Kode,Merk/Tipe,Tgl Beli,Maks Hari,Catatan\n"
        for b in batteries {
            let row = [
                escapeCSV(b.code),
                escapeCSV(b.brandAndType),
                dateFormatter.string(from: b.purchasedDate),
                "\(b.maxDays)",
                escapeCSV(b.notes)
            ].joined(separator: ",")
            csv += "\(row)\n"
        }
        
        csv += "\n=== LIQUIDS ===\n"
        csv += "Nama Liquid,Tgl Buka,Maks Hari,Nikotin,Volume\n"
        for l in liquids {
            let row = [
                escapeCSV(l.name),
                dateFormatter.string(from: l.openedDate),
                "\(l.maxDays)",
                escapeCSV(l.nicMg),
                escapeCSV(l.volumeMl)
            ].joined(separator: ",")
            csv += "\(row)\n"
        }
        
        csv += "\n=== MAINTENANCE AUDIT LOGS ===\n"
        csv += "Tank,Aksi,Tanggal,Catatan\n"
        for m in logs {
            let row = [
                escapeCSV(m.tankName),
                m.actionType,
                dateFormatter.string(from: m.date),
                escapeCSV(m.notes)
            ].joined(separator: ",")
            csv += "\(row)\n"
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("VapeCare_Report_\(dateStamp()).csv")
        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func dateStamp() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd_HHmm"
        return df.string(from: Date())
    }
    
    private func escapeCSV(_ text: String) -> String {
        if text.contains(",") || text.contains("\"") || text.contains("\n") {
            let escaped = text.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return text
    }
}
