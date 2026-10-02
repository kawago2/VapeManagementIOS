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
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Dashboard.coilStatus)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(overdueCoilCount > 0 ? L10n.Dashboard.needsCheck(overdueCoilCount) : String(localized: "common.all_good"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(overdueCoilCount > 0 ? Color.red : Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.02), radius: 4, y: 1)
            
            // Cotton Summary Pill
            HStack(spacing: 8) {
                Circle()
                    .fill(overdueCottonCount > 0 ? Color.red : Color.green)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Dashboard.cottonStatus)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(overdueCottonCount > 0 ? L10n.Dashboard.needChange(overdueCottonCount) : String(localized: "common.all_good"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(overdueCottonCount > 0 ? Color.red : Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(0.02), radius: 4, y: 1)
        }
    }
}
