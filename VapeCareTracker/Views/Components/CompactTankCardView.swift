import SwiftUI

struct CompactTankCardView: View {
    let tank: TankSetup
    let liquids: [LiquidItem]
    let onSelectLiquid: (String) -> Void
    let onQuickResetCoil: () -> Void
    let onQuickResetCotton: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var isCoilOverdue: Bool {
        tank.coilHealthStatus.isOverdue
    }
    
    private var isCottonOverdue: Bool {
        tank.cottonHealthStatus.isOverdue
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tank.tankName)
                        .font(.system(size: 15, weight: .bold))
                    Text(tank.wireType)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Liquid Selector Tag
                Menu {
                    ForEach(liquids) { liquid in
                        Button(liquid.name) {
                            onSelectLiquid(liquid.name)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.blue)
                        Text(tank.activeLiquidName)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            Divider()
                .padding(.horizontal, 14)
            
            // Metrics Row
            HStack(spacing: 0) {
                // Coil Metric
                let coilProgress = min(1.0, Double(tank.coilDaysPassed) / Double(max(1, tank.coilMaxDays)))
                let coilColor: Color = isCoilOverdue ? .red : (coilProgress >= 0.75 ? .orange : .green)
                
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.Dashboard.Sections.tanks)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(tank.coilDaysPassed)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(isCoilOverdue ? Color.red : (coilProgress >= 0.75 ? Color.orange : Color.primary))
                            Text("/ \(tank.coilMaxDays)d")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        // Mini Progress Gauge
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 3)
                                Capsule()
                                    .fill(coilColor)
                                    .frame(width: max(3, geo.size.width * CGFloat(coilProgress)), height: 3)
                            }
                        }
                        .frame(height: 3)
                        .padding(.top, 2)
                    }
                    
                    Spacer(minLength: 4)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onQuickResetCoil()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                
                Divider()
                    .frame(height: 36)
                
                // Cotton Metric
                let cottonProgress = min(1.0, Double(tank.cottonDaysPassed) / Double(max(1, tank.cottonMaxDays)))
                let cottonColor: Color = isCottonOverdue ? .red : (cottonProgress >= 0.75 ? .orange : .green)
                
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.History.filterCotton)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(tank.cottonDaysPassed)")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(isCottonOverdue ? Color.red : (cottonProgress >= 0.75 ? Color.orange : Color.primary))
                            Text("/ \(tank.cottonMaxDays)d")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        // Mini Progress Gauge
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 3)
                                Capsule()
                                    .fill(cottonColor)
                                    .frame(width: max(3, geo.size.width * CGFloat(cottonProgress)), height: 3)
                            }
                        }
                        .frame(height: 3)
                        .padding(.top, 2)
                    }
                    
                    Spacer(minLength: 4)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onQuickResetCotton()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(Color(.systemGray6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 5, y: 1)
        .contextMenu {
            Button(L10n.Dashboard.Actions.editSetup, action: onEdit)
            Button(L10n.Dashboard.Actions.deleteTank, role: .destructive, action: onDelete)
        }
    }
}
