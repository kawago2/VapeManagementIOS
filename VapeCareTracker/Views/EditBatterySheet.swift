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
                Section("Identitas Baterai") {
                    TextField("ID Baterai (misal: BAT-01)", text: $code)
                    TextField("Merek / Tipe (misal: PVR Battery 18650)", text: $brandAndType)
                    TextField("Catatan / Pasangan (opsional)", text: $notes)
                }
                
                Section {
                    DatePicker(
                        "Tanggal Beli",
                        selection: $purchasedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    Stepper("Batas Masa Pakai: \(maxDays) Hari", value: $maxDays, in: 30...730, step: 15)
                } header: {
                    Text("Riwayat & Batas Pakai")
                }
            }
            .navigationTitle(battery == nil ? "Tambah Baterai" : "Ubah Baterai")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
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
