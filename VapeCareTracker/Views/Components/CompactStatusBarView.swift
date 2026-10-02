import SwiftUI

struct CompactStatusBarView: View {
    let overdueCoilCount: Int
    let overdueCottonCount: Int
    
    var body: some View {
        HStack(spacing: 10) {
            // Coil Summary Pill
            HStack(spacing: 8) {
                Circle()
                    .fill(overdueCoilCount > 0 ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("COIL STATUS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(overdueCoilCount > 0 ? "\(overdueCoilCount) " + String(localized: "Needs Check") : String(localized: "All Good"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(overdueCoilCount > 0 ? Color.red : Color.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.02), radius: 4, y: 1)
            
            // Cotton Summary Pill
            HStack(spacing: 8) {
                Circle()
                    .fill(overdueCottonCount > 0 ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("COTTON STATUS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text(overdueCottonCount > 0 ? "\(overdueCottonCount) " + String(localized: "Needs Replacement") : String(localized: "All Good"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(overdueCottonCount > 0 ? Color.red : Color.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.02), radius: 4, y: 1)
        }
    }
}
