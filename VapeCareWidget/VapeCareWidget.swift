import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Provider
struct VapeCareWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> VapeCareWidgetEntry {
        VapeCareWidgetEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (VapeCareWidgetEntry) -> Void) {
        let snapshot = WidgetDataStore.shared.loadSnapshot() ?? .placeholder
        let entry = VapeCareWidgetEntry(date: Date(), snapshot: snapshot)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VapeCareWidgetEntry>) -> Void) {
        let snapshot = WidgetDataStore.shared.loadSnapshot() ?? .placeholder
        let currentDate = Date()
        let entry = VapeCareWidgetEntry(date: currentDate, snapshot: snapshot)
        
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate.addingTimeInterval(1800)
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

// MARK: - Small Widget (Compact Card)
private struct SmallWidgetView: View {
    let snapshot: WidgetTankSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "atom")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.purple)
                Text(snapshot.tankName)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Coil Progress
            HealthRow(
                icon: "flame.fill",
                title: "Coil",
                daysPassed: snapshot.coilDaysPassed,
                maxDays: snapshot.coilMaxDays,
                isOverdue: snapshot.coilOverdue,
                tint: .orange
            )
            
            // Cotton Progress
            HealthRow(
                icon: "wind",
                title: "Kapas",
                daysPassed: snapshot.cottonDaysPassed,
                maxDays: snapshot.cottonMaxDays,
                isOverdue: snapshot.cottonOverdue,
                tint: .blue
            )
        }
        .containerBackground(for: .widget) {
            Color(.secondarySystemBackground)
        }
    }
}

// MARK: - Medium Widget (Wide Detailed Card)
private struct MediumWidgetView: View {
    let snapshot: WidgetTankSnapshot
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "atom")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.purple)
                    Text(snapshot.tankName)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                }
                
                Text(snapshot.wireType)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.pink)
                    Text(snapshot.activeLiquid.isEmpty ? "Tidak ada liquid" : snapshot.activeLiquid)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
            }
            
            Divider()
            
            VStack(spacing: 10) {
                HealthGauge(
                    title: "Coil Health",
                    daysPassed: snapshot.coilDaysPassed,
                    maxDays: snapshot.coilMaxDays,
                    isOverdue: snapshot.coilOverdue,
                    tint: .orange
                )
                
                HealthGauge(
                    title: "Cotton Health",
                    daysPassed: snapshot.cottonDaysPassed,
                    maxDays: snapshot.cottonMaxDays,
                    isOverdue: snapshot.cottonOverdue,
                    tint: .blue
                )
            }
        }
        .containerBackground(for: .widget) {
            Color(.secondarySystemBackground)
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
