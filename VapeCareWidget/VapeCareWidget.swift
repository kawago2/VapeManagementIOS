import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Timeline Provider
struct VapeCareWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> VapeCareWidgetEntry {
        VapeCareWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (VapeCareWidgetEntry) -> Void) {
        let snapshot = WidgetDataStore.shared.loadSnapshot()
        let entry = VapeCareWidgetEntry(date: Date(), snapshot: snapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VapeCareWidgetEntry>) -> Void) {
        let snapshot = WidgetDataStore.shared.loadSnapshot()
        let currentDate = Date()
        let entry = VapeCareWidgetEntry(date: currentDate, snapshot: snapshot)
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry
struct VapeCareWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetTankSnapshot
}

// MARK: - Widget Views
struct VapeCareWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: VapeCareWidgetProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            MediumWidgetView(snapshot: entry.snapshot)
        default:
            SmallWidgetView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - Small Widget (Interactive Carousel via Next/Prev Buttons)
private struct SmallWidgetView: View {
    let snapshot: WidgetTankSnapshot
    
    private var tank: WidgetTankItem? {
        snapshot.currentTank
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with navigation arrows
            HStack {
                Image(systemName: "atom")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.purple)
                
                Text(tank?.tankName ?? "Belum Ada Tank")
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                
                Spacer()
                
                if snapshot.tanks.count > 1 {
                    HStack(spacing: 8) {
                        Button(intent: PrevTankIntent()) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(intent: NextTankIntent()) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            if let activeTank = tank {
                Spacer()
                
                HealthRow(
                    icon: "flame.fill",
                    title: "Coil",
                    daysPassed: activeTank.coilDaysPassed,
                    maxDays: activeTank.coilMaxDays,
                    isOverdue: activeTank.coilOverdue,
                    tint: .orange
                )
                
                HealthRow(
                    icon: "wind",
                    title: "Kapas",
                    daysPassed: activeTank.cottonDaysPassed,
                    maxDays: activeTank.cottonMaxDays,
                    isOverdue: activeTank.cottonOverdue,
                    tint: .blue
                )
                
                // Index indicator dots
                if snapshot.tanks.count > 1 {
                    HStack(spacing: 3) {
                        ForEach(0..<snapshot.tanks.count, id: \.self) { idx in
                            Circle()
                                .fill(idx == snapshot.selectedIndex ? Color.primary : Color.secondary.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.top, 2)
                }
            } else {
                Spacer()
                Text("Buka aplikasi untuk menambah tank.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color.black
        }
    }
}

// MARK: - Medium Widget (Interactive Carousel Card with Gauges)
private struct MediumWidgetView: View {
    let snapshot: WidgetTankSnapshot
    
    private var tank: WidgetTankItem? {
        snapshot.currentTank
    }
    
    var body: some View {
        if let activeTank = tank {
            HStack(spacing: 16) {
                // Left Column: Tank Details & Navigation
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "atom")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.purple)
                        Text(activeTank.tankName)
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(1)
                    }
                    
                    Text(activeTank.wireType)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.pink)
                        Text(activeTank.activeLiquid.isEmpty ? "Tidak ada liquid" : activeTank.activeLiquid)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    
                    // Carousel Pagination Controls (◀ 1/3 ▶)
                    if snapshot.tanks.count > 1 {
                        HStack(spacing: 12) {
                            Button(intent: PrevTankIntent()) {
                                Image(systemName: "chevron.backward.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.secondary)
                            }
                            .buttonStyle(.plain)
                            
                            Text("\(snapshot.selectedIndex + 1) / \(snapshot.tanks.count)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                            
                            Button(intent: NextTankIntent()) {
                                Image(systemName: "chevron.forward.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 2)
                    }
                }
                
                Divider()
                
                // Right Column: Live Health Gauges
                VStack(spacing: 10) {
                    HealthGauge(
                        title: "Coil Health",
                        daysPassed: activeTank.coilDaysPassed,
                        maxDays: activeTank.coilMaxDays,
                        isOverdue: activeTank.coilOverdue,
                        tint: .orange
                    )
                    
                    HealthGauge(
                        title: "Cotton Health",
                        daysPassed: activeTank.cottonDaysPassed,
                        maxDays: activeTank.cottonMaxDays,
                        isOverdue: activeTank.cottonOverdue,
                        tint: .blue
                    )
                }
            }
            .containerBackground(for: .widget) {
                Color.black
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "atom")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Belum ada tank vape tersimpan")
                    .font(.subheadline.bold())
            }
            .containerBackground(for: .widget) {
                Color.black
            }
        }
    }
}

// MARK: - Helper Subviews
private struct HealthRow: View {
    let icon: String
    let title: String
    let daysPassed: Int
    let maxDays: Int
    let isOverdue: Bool
    let tint: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 11, weight: .medium))
            Spacer()
            Text("\(daysPassed)/\(maxDays)h")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isOverdue ? .red : tint)
        }
    }
}

private struct HealthGauge: View {
    let title: String
    let daysPassed: Int
    let maxDays: Int
    let isOverdue: Bool
    let tint: Color
    
    private var progress: Double {
        guard maxDays > 0 else { return 0 }
        return min(1.0, Double(daysPassed) / Double(maxDays))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
                Text("\(daysPassed)/\(maxDays) hr")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isOverdue ? .red : .primary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 6)
                    Capsule()
                        .fill(isOverdue ? Color.red : tint)
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Widget Definition
@main
struct VapeCareWidget: Widget {
    let kind: String = "VapeCareWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VapeCareWidgetProvider()) { entry in
            VapeCareWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("VapeCare Tracker")
        .description("Pantau status coil dan kapas tank vape aktif kamu secara langsung.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
