import SwiftUI
import SwiftData

struct EditTankSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var tank: TankSetup?
    var existingLiquids: [LiquidItem]
    var onSaveTank: ((String, String, Date, Date, String, Int, Int) -> Void)? = nil
    
    @State private var tankName: String = ""
    @State private var wireType: String = ""
    @State private var coilInstalledDate: Date = Date()
    @State private var cottonReplacedDate: Date = Date()
    @State private var activeLiquidName: String = ""
    @State private var coilMaxDays: Int = 14
    @State private var cottonMaxDays: Int = 4
    
    init(
        tank: TankSetup? = nil,
        existingLiquids: [LiquidItem] = [],
        onSaveTank: ((String, String, Date, Date, String, Int, Int) -> Void)? = nil
    ) {
        self.tank = tank
        self.existingLiquids = existingLiquids
        self.onSaveTank = onSaveTank
        _tankName = State(initialValue: tank?.tankName ?? "")
        _wireType = State(initialValue: tank?.wireType ?? "")
        _coilInstalledDate = State(initialValue: tank?.coilInstalledDate ?? Date())
        _cottonReplacedDate = State(initialValue: tank?.cottonReplacedDate ?? Date())
        _activeLiquidName = State(initialValue: tank?.activeLiquidName ?? (existingLiquids.first?.name ?? "Tanpa Liquid"))
        _coilMaxDays = State(initialValue: tank?.coilMaxDays ?? 14)
        _cottonMaxDays = State(initialValue: tank?.cottonMaxDays ?? 4)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tank & Wire Identity") {
                    TextField("Device / Tank (e.g. TRML Tank)", text: $tankName)
                    TextField("Installed Wire (e.g. Baby Alien 0.35Ω)", text: $wireType)
                    
                    Picker("Active E-Liquid", selection: $activeLiquidName) {
                        if existingLiquids.isEmpty {
                            Text("No liquid data available").tag("")
                        } else {
                            ForEach(existingLiquids) { liquid in
                                Text(liquid.name).tag(liquid.name)
                            }
                        }
                    }
                }
                
                Section {
                    DatePicker(
                        "Coil Installation Date",
                        selection: $coilInstalledDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    Stepper("Coil Lifespan Limit: \(coilMaxDays) Days", value: $coilMaxDays, in: 1...60)
                } header: {
                    Text("Coil Settings")
                }
                
                Section {
                    DatePicker(
                        "Cotton Replacement Date",
                        selection: $cottonReplacedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    Stepper("Cotton Lifespan Limit: \(cottonMaxDays) Days", value: $cottonMaxDays, in: 1...30)
                } header: {
                    Text("Cotton Settings")
                }
            }
            .navigationTitle(tank == nil ? "Add Tank" : "Edit Tank Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSaveTank?(
                            tankName,
                            wireType,
                            coilInstalledDate,
                            cottonReplacedDate,
                            activeLiquidName,
                            coilMaxDays,
                            cottonMaxDays
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(tankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
