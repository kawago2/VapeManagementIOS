import SwiftUI

struct CompactBatteryRowView: View {
    let battery: BatteryItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var isOverdue: Bool {
        battery.healthStatus.isOverdue
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: battery.purchasedDate)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(battery.code)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(battery.brandAndType)
                    .font(.system(size: 13, weight: .medium))
                if !battery.notes.isEmpty {
                    Text(battery.notes)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(formattedDate)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            
            Text("\(battery.daysPassed)d")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isOverdue ? Color.red : Color.primary)
                .frame(minWidth: 44, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 3, y: 1)
        .contextMenu {
            Button(L10n.Common.edit, action: onEdit)
            Button(L10n.Common.delete, role: .destructive, action: onDelete)
        }
    }
}
