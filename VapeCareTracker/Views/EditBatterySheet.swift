import SwiftUI
import SwiftData

struct EditBatterySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var battery: BatteryItem?
    var onSaveBattery: ((String, String, Date, Int, String) -> Void)? = nil
    
    @State private var code: String = ""
    @State private var brandAndType: String = ""
    @State private var purchasedDate: Date = Date()
    @State private var maxDays: Int = 365
    @State private var notes: String = ""
    
    init(battery: BatteryItem? = nil, onSaveBattery: ((String, String, Date, Int, String) -> Void)? = nil) {
        self.battery = battery
        self.onSaveBattery = onSaveBattery
        _code = State(initialValue: battery?.code ?? "")
        _brandAndType = State(initialValue: battery?.brandAndType ?? "")
        _purchasedDate = State(initialValue: battery?.purchasedDate ?? Date())
        _maxDays = State(initialValue: battery?.maxDays ?? 365)
        _notes = State(initialValue: battery?.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.BatteryForm.identitySection) {
                    TextField(L10n.BatteryForm.idPlaceholder, text: $code)
                    TextField(L10n.BatteryForm.brandPlaceholder, text: $brandAndType)
                    TextField(L10n.BatteryForm.notesPlaceholder, text: $notes)
                }
                
                Section {
                    DatePicker(
                        L10n.BatteryForm.purchaseDate,
                        selection: $purchasedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    Stepper(L10n.BatteryForm.lifespanLimit(maxDays), value: $maxDays, in: 30...730, step: 15)
                } header: {
                    Text(L10n.BatteryForm.historySection)
                }
            }
            .navigationTitle(battery == nil ? L10n.BatteryForm.addTitle : L10n.BatteryForm.editTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        onSaveBattery?(code, brandAndType, purchasedDate, maxDays, notes)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(code.isEmpty || brandAndType.isEmpty)
                }
            }
        }
    }
}
