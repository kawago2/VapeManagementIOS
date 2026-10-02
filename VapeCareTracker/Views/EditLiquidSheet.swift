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
                Section(L10n.LiquidForm.identitySection) {
                    TextField(L10n.LiquidForm.namePlaceholder, text: $name)
                    
                    HStack {
                        TextField(L10n.LiquidForm.nicPlaceholder, text: $nicMg)
                        Divider()
                        TextField(L10n.LiquidForm.volumePlaceholder, text: $volumeMl)
                    }
                }
                
                Section {
                    DatePicker(
                        L10n.LiquidForm.openedDate,
                        selection: $openedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    Stepper(L10n.LiquidForm.shelfLifeLimit(maxDays), value: $maxDays, in: 30...365, step: 15)
                } header: {
                    Text(L10n.LiquidForm.historySection)
                } footer: {
                    Text(L10n.LiquidForm.shelfLifeFooter)
                }
            }
            .navigationTitle(liquid == nil ? L10n.LiquidForm.addTitle : L10n.LiquidForm.editTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
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
