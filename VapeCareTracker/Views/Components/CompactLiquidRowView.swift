import SwiftUI

struct CompactLiquidRowView: View {
    let liquid: LiquidItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var isOverdue: Bool {
        liquid.healthStatus.isOverdue
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy"
        return formatter.string(from: liquid.openedDate)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "drop.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color.blue.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 1) {
                Text(liquid.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text("\(liquid.nicMg) • \(liquid.volumeMl)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(formattedDate)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            
            Text("\(liquid.daysPassed) hr")
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
            Button("Edit", action: onEdit)
            Button("Hapus", role: .destructive, action: onDelete)
        }
    }
}
