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
                Section(L10n.TankForm.identitySection) {
                    TextField(L10n.TankForm.devicePlaceholder, text: $tankName)
                    TextField(L10n.TankForm.wirePlaceholder, text: $wireType)
                    
                    Picker(L10n.TankForm.activeLiquid, selection: $activeLiquidName) {
                        if existingLiquids.isEmpty {
                            Text(L10n.TankForm.noLiquid).tag("")
                        } else {
                            ForEach(existingLiquids) { liquid in
                                Text(liquid.name).tag(liquid.name)
                            }
                        }
                    }
                }
                
                Section {
                    DatePicker(
                        L10n.TankForm.coilDate,
                        selection: $coilInstalledDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    Stepper(L10n.TankForm.coilLimit(coilMaxDays), value: $coilMaxDays, in: 1...60)
                } header: {
                    Text(L10n.TankForm.coilSection)
                }
                
                Section {
                    DatePicker(
                        L10n.TankForm.cottonDate,
                        selection: $cottonReplacedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    Stepper(L10n.TankForm.cottonLimit(cottonMaxDays), value: $cottonMaxDays, in: 1...30)
                } header: {
                    Text(L10n.TankForm.cottonSection)
                }
            }
            .navigationTitle(tank == nil ? L10n.TankForm.addTitle : L10n.TankForm.editTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
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
