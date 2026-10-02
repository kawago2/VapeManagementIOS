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
                Section("Battery Identity") {
                    TextField("Battery ID (e.g. BAT-01)", text: $code)
                    TextField("Brand / Model (e.g. PVR Battery 18650)", text: $brandAndType)
                    TextField("Notes / Paired Set (optional)", text: $notes)
                }
                
                Section {
                    DatePicker(
                        "Purchase Date",
                        selection: $purchasedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    Stepper("Lifespan Limit: \(maxDays) Days", value: $maxDays, in: 30...730, step: 15)
                } header: {
                    Text("History & Lifespan Limit")
                }
            }
            .navigationTitle(battery == nil ? "Add Battery" : "Edit Battery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
