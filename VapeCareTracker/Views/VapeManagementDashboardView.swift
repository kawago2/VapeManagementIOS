import SwiftUI
import SwiftData

struct VapeManagementDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: VapeDashboardViewModel
    
    // Segmented / Tab view filter for compact modern browsing
    enum DashboardTab: String, CaseIterable, Identifiable {
        case overview = "All"
        case tanks = "Tanks & Coils"
        case batteries = "Batteries"
        case liquids = "E-Liquids"
        
        var id: String { rawValue }
        
        var title: LocalizedStringKey {
            switch self {
            case .overview: return "All"
            case .tanks: return "Tanks & Coils"
            case .batteries: return "Batteries"
            case .liquids: return "E-Liquids"
            }
        }
        
        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .tanks: return "atom"
            case .batteries: return "battery.100.bolt"
            case .liquids: return "drop.fill"
            }
        }
    }
    
    @State private var selectedTab: DashboardTab = .overview
    
    // Sheet Presentations
    @State private var tankToEdit: TankSetup? = nil
    @State private var isAddingTank: Bool = false
    
    @State private var batteryToEdit: BatteryItem? = nil
    @State private var isAddingBattery: Bool = false
    
    @State private var liquidToEdit: LiquidItem? = nil
    @State private var isAddingLiquid: Bool = false
    
    @State private var showingCloudSettings: Bool = false
    @State private var showingMaintenanceHistory: Bool = false
    @State private var isAnimatingRefresh: Bool = false
    @ObservedObject private var syncService = TursoSyncService.shared
    
    // Quick Reset Alerts
    @State private var quickResetTank: TankSetup? = nil
    @State private var quickResetTarget: String? = nil
    @State private var showingQuickResetAlert: Bool = false
    
    // Delete Confirmation
    @State private var itemToDelete: AnyIdentifiableItem? = nil
    @State private var showingDeleteAlert: Bool = false
    
    init(repository: VapeDataRepositoryProtocol) {
        _viewModel = StateObject(wrappedValue: VapeDashboardViewModel(repository: repository))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // 1. Compact Status Summary Pills
                    CompactStatusBarView(
                        overdueCoilCount: viewModel.overdueCoilCount,
                        overdueCottonCount: viewModel.overdueCottonCount
                    )
                    
                    // 2. Segmented Pill Filter
                    tabFilterBar
                    
                    // 3. Content Sections based on Tab
                    if selectedTab == .overview || selectedTab == .tanks {
                        tankSection
                    }
                    
                    if selectedTab == .overview || selectedTab == .batteries {
                        batterySection
                    }
                    
                    if selectedTab == .overview || selectedTab == .liquids {
                        liquidSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .refreshable {
                await viewModel.syncWithCloud()
            }
            .searchable(text: $viewModel.searchText, prompt: "Search tanks, batteries, or liquids...")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Vape Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingCloudSettings = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: syncService.isConnected ? "cloud.fill" : "cloud")
                                .font(.system(size: 15))
                                .foregroundStyle(syncService.isConnected ? Color.blue : Color.secondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingMaintenanceHistory = true
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.primary)
                        }
                        
                        Button {
                            Task {
                                await viewModel.syncWithCloud()
                            }
                        } label: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(syncService.isConnected ? Color.blue : Color.secondary)
                                .rotationEffect(.degrees(isAnimatingRefresh ? 360 : 0))
                        }
                        .disabled(viewModel.isRefreshing)
                        .onChange(of: viewModel.isRefreshing) { _, refreshing in
                            if refreshing {
                                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                                    isAnimatingRefresh = true
                                }
                            } else {
                                withAnimation(.default) {
                                    isAnimatingRefresh = false
                                }
                            }
                        }
                        
                        addMenuButton
                    }
                }
            }
            .sheet(isPresented: $showingCloudSettings) {
                CloudSettingsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingMaintenanceHistory) {
                MaintenanceHistorySheet(viewModel: viewModel)
            }
            .sheet(isPresented: $isAddingTank) {
                EditTankSetupSheet(tank: nil, existingLiquids: viewModel.liquids) { name, wire, coilDate, cottonDate, liquid, coilMax, cottonMax in
                    viewModel.saveTank(
                        existing: nil,
                        tankName: name,
                        wireType: wire,
                        coilInstalledDate: coilDate,
                        cottonReplacedDate: cottonDate,
                        activeLiquidName: liquid,
                        coilMaxDays: coilMax,
                        cottonMaxDays: cottonMax
                    )
                }
            }
            .sheet(item: $tankToEdit) { tank in
                EditTankSetupSheet(tank: tank, existingLiquids: viewModel.liquids) { name, wire, coilDate, cottonDate, liquid, coilMax, cottonMax in
                    viewModel.saveTank(
                        existing: tank,
                        tankName: name,
                        wireType: wire,
                        coilInstalledDate: coilDate,
                        cottonReplacedDate: cottonDate,
                        activeLiquidName: liquid,
                        coilMaxDays: coilMax,
                        cottonMaxDays: cottonMax
                    )
                }
            }
            .sheet(isPresented: $isAddingBattery) {
                EditBatterySheet(battery: nil) { code, brand, buyDate, maxDays, notes in
                    viewModel.saveBattery(
                        existing: nil,
                        code: code,
                        brandAndType: brand,
                        purchasedDate: buyDate,
                        maxDays: maxDays,
                        notes: notes
                    )
                }
            }
            .sheet(item: $batteryToEdit) { battery in
                EditBatterySheet(battery: battery) { code, brand, buyDate, maxDays, notes in
                    viewModel.saveBattery(
                        existing: battery,
                        code: code,
                        brandAndType: brand,
                        purchasedDate: buyDate,
                        maxDays: maxDays,
                        notes: notes
                    )
                }
            }
            .sheet(isPresented: $isAddingLiquid) {
                EditLiquidSheet(liquid: nil) { name, openDate, maxDays, nic, vol in
                    viewModel.saveLiquid(
                        existing: nil,
                        name: name,
                        openedDate: openDate,
                        maxDays: maxDays,
                        nicMg: nic,
                        volumeMl: vol
                    )
                }
            }
            .sheet(item: $liquidToEdit) { liquid in
                EditLiquidSheet(liquid: liquid) { name, openDate, maxDays, nic, vol in
                    viewModel.saveLiquid(
                        existing: liquid,
                        name: name,
                        openedDate: openDate,
                        maxDays: maxDays,
                        nicMg: nic,
                        volumeMl: vol
                    )
                }
            }
            .alert("Confirm Reset", isPresented: $showingQuickResetAlert, presenting: quickResetTank) { tank in
                Button("Cancel", role: .cancel) {}
                Button("Yes, Just Replaced") {
                    if quickResetTarget == "cotton" {
                        viewModel.quickResetCotton(for: tank)
                    } else if quickResetTarget == "coil" {
                        viewModel.quickResetCoil(for: tank)
                    }
                }
            } message: { tank in
                Text("Update replacement date of \(quickResetTarget == "cotton" ? "cotton" : "coil") for '\(tank.tankName)' to today?")
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert, presenting: itemToDelete) { item in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    performDelete(item)
                }
            } message: { item in
                Text("Are you sure you want to delete '\(item.title)'?")
            }
            .task {
                await viewModel.onAppear()
            }
        }
        .overlay(alignment: .top) {
            if let toast = viewModel.toastMessage {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isToastError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(viewModel.isToastError ? Color.red : Color.green)
                    
                    Text(toast)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.18), radius: 10, y: 5)
                .padding(.top, 12)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
                .zIndex(9999)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.toastMessage)
    }
    
    // MARK: - Toolbar & Header Views
    private var addMenuButton: some View {
        Menu {
            Button { isAddingTank = true } label: { Label("Add Tank", systemImage: "atom") }
            Button { isAddingBattery = true } label: { Label("Add Battery", systemImage: "battery.100.bolt") }
            Button { isAddingLiquid = true } label: { Label("Add E-Liquid", systemImage: "drop.fill") }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(red: 0.05, green: 0.30, blue: 0.60))
        }
    }
    
    private var tabFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DashboardTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelected ? Color(red: 0.05, green: 0.25, blue: 0.5) : Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 3, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    // MARK: - Sections
    private var tankSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "TANKS & SETUPS", count: viewModel.filteredTanks.count, onAdd: { isAddingTank = true })
            
            if viewModel.filteredTanks.isEmpty {
                emptyPlaceholder(text: viewModel.searchText.isEmpty ? "No tanks set up yet." : "No matching tanks found.")
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.filteredTanks) { tank in
                        CompactTankCardView(
                            tank: tank,
                            liquids: viewModel.liquids,
                            onSelectLiquid: { name in viewModel.updateActiveLiquid(for: tank, liquidName: name) },
                            onQuickResetCoil: {
                                quickResetTank = tank
                                quickResetTarget = "coil"
                                showingQuickResetAlert = true
                            },
                            onQuickResetCotton: {
                                quickResetTank = tank
                                quickResetTarget = "cotton"
                                showingQuickResetAlert = true
                            },
                            onEdit: { tankToEdit = tank },
                            onDelete: {
                                itemToDelete = AnyIdentifiableItem(id: tank.id, title: tank.tankName, rawType: .tank(tank))
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var batterySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "BATTERY INVENTORY", count: viewModel.filteredBatteries.count, onAdd: { isAddingBattery = true })
            
            if viewModel.filteredBatteries.isEmpty {
                emptyPlaceholder(text: viewModel.searchText.isEmpty ? "No batteries registered." : "No matching batteries found.")
            } else {
                VStack(spacing: 6) {
                    ForEach(viewModel.filteredBatteries) { battery in
                        CompactBatteryRowView(
                            battery: battery,
                            onEdit: { batteryToEdit = battery },
                            onDelete: {
                                itemToDelete = AnyIdentifiableItem(id: battery.id, title: "\(battery.code) - \(battery.brandAndType)", rawType: .battery(battery))
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var liquidSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "LIQUID COLLECTION", count: viewModel.filteredLiquids.count, onAdd: { isAddingLiquid = true })
            
            if viewModel.filteredLiquids.isEmpty {
                emptyPlaceholder(text: viewModel.searchText.isEmpty ? "No liquids registered." : "No matching liquids found.")
            } else {
                VStack(spacing: 6) {
                    ForEach(viewModel.filteredLiquids) { liquid in
                        CompactLiquidRowView(
                            liquid: liquid,
                            onEdit: { liquidToEdit = liquid },
                            onDelete: {
                                itemToDelete = AnyIdentifiableItem(id: liquid.id, title: liquid.name, rawType: .liquid(liquid))
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Subview Helpers
    private func sectionHeader(title: String, count: Int, onAdd: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            
            Text("(\(count))")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
            
            Spacer()
            
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(5)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }
    
    private func emptyPlaceholder(text: String, icon: String = "tray") -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func performDelete(_ item: AnyIdentifiableItem) {
        switch item.rawType {
        case .tank(let tank): viewModel.deleteTank(tank)
        case .battery(let battery): viewModel.deleteBattery(battery)
        case .liquid(let liquid): viewModel.deleteLiquid(liquid)
        }
    }
}
