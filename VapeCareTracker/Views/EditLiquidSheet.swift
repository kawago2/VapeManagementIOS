import SwiftUI
import SwiftData

struct EditLiquidSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var liquid: LiquidItem?
    var onSaveLiquid: ((String, Date, Int, String, String) -> Void)? = nil
    
    @State private var name: String = ""
    @State private var openedDate: Date = Date()
    @State private var maxDays: Int = 90
    @State private var nicMg: String = "3mg"
    @State private var volumeMl: String = "60ml"
    
    init(liquid: LiquidItem? = nil, onSaveLiquid: ((String, Date, Int, String, String) -> Void)? = nil) {
        self.liquid = liquid
        self.onSaveLiquid = onSaveLiquid
        _name = State(initialValue: liquid?.name ?? "")
        _openedDate = State(initialValue: liquid?.openedDate ?? Date())
        _maxDays = State(initialValue: liquid?.maxDays ?? 90)
        _nicMg = State(initialValue: liquid?.nicMg ?? "3mg")
        _volumeMl = State(initialValue: liquid?.volumeMl ?? "60ml")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("E-Liquid Identity") {
                    TextField("E-Liquid Name (e.g. Butterbread Peanut Butter)", text: $name)
                    
                    HStack {
                        TextField("Nicotine (e.g. 3mg)", text: $nicMg)
                        Divider()
                        TextField("Volume (e.g. 60ml)", text: $volumeMl)
                    }
                }
                
                Section {
                    DatePicker(
                        "Opened / Purchase Date",
                        selection: $openedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    Stepper("Shelf Life Limit: \(maxDays) Days", value: $maxDays, in: 30...365, step: 15)
                } header: {
                    Text("History & Liquid Age")
                } footer: {
                    Text("Opened bottles are typically recommended to be consumed within 30 - 90 days for optimal flavor and nicotine profile.")
                }
            }
            .navigationTitle(liquid == nil ? "Add E-Liquid" : "Edit E-Liquid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSaveLiquid?(name.trimmingCharacters(in: .whitespacesAndNewlines), openedDate, maxDays, nicMg, volumeMl)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
