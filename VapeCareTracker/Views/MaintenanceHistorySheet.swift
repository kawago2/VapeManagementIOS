import SwiftUI

struct MaintenanceHistorySheet: View {
    @ObservedObject var viewModel: VapeDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var filterAction: String = "all" // "all", "coil", "cotton"
    
    private var filteredLogs: [MaintenanceLog] {
        let logs = viewModel.maintenanceLogs
        if filterAction == "all" {
            return logs
        }
        return logs.filter { $0.actionType == filterAction }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.maintenanceLogs.isEmpty {
                    ContentUnavailableView(
                        "Belum Ada Riwayat",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Riwayat pergantian coil dan kapas pada tank kamu akan otomatis tercatat di sini.")
                    )
                } else {
                    List {
                        Section {
                            Picker("Filter Tipe", selection: $filterAction) {
                                Text("Semua").tag("all")
                                Text("Coil").tag("coil")
                                Text("Kapas").tag("cotton")
                            }
                            .pickerStyle(.segmented)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                        }
                        
                        Section {
                            ForEach(filteredLogs) { log in
                                MaintenanceLogRow(log: log)
                            }
                            .onDelete(perform: deleteLog)
                        } header: {
                            Text("Daftar Aktivitas (\(filteredLogs.count))")
                                .font(.caption.bold())
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Riwayat Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Selesai") {
                        dismiss()
                    }
                    .font(.body.bold())
                }
            }
        }
    }
    
    private func deleteLog(at offsets: IndexSet) {
        for index in offsets {
            let log = filteredLogs[index]
            viewModel.deleteMaintenanceLog(log)
        }
    }
}

// MARK: - Subview Row Component
private struct MaintenanceLogRow: View {
    let log: MaintenanceLog
    
    private var isCoil: Bool {
        log.actionType == "coil"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCoil ? Color.orange.opacity(0.15) : Color.blue.opacity(0.15))
                    .frame(width: 38, height: 38)
                
                Image(systemName: isCoil ? "flame.fill" : "wind")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isCoil ? Color.orange : Color.blue)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(log.tankName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    Text(formattedDate(log.date))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
                
                HStack(spacing: 6) {
                    Text(isCoil ? "Ganti Coil" : "Ganti Kapas")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isCoil ? Color.orange.opacity(0.12) : Color.blue.opacity(0.12))
                        .foregroundStyle(isCoil ? Color.orange : Color.blue)
                        .clipShape(Capsule())
                    
                    if !log.notes.isEmpty {
                        Text("• \(log.notes)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
