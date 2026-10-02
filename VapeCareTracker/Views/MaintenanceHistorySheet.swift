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
                        L10n.History.emptyTitle,
                        systemImage: "clock.arrow.circlepath",
                        description: Text(L10n.History.emptyDescription)
                    )
                } else {
                    List {
                        Section {
                            Picker(L10n.History.filterType, selection: $filterAction) {
                                Text(L10n.History.filterAll).tag("all")
                                Text(L10n.History.filterCoil).tag("coil")
                                Text(L10n.History.filterCotton).tag("cotton")
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
                            Text(L10n.History.activityList(filteredLogs.count))
                                .font(.caption.bold())
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(L10n.History.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.done) {
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
                    Text(isCoil ? L10n.History.coilChanged : L10n.History.cottonChanged)
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
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
