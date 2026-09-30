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
                Section("Identitas Liquid") {
                    TextField("Nama Liquid (misal: Butterbread Peanut Butter)", text: $name)
                    
                    HStack {
                        TextField("Nikotin (misal: 3mg)", text: $nicMg)
                        Divider()
                        TextField("Volume (misal: 60ml)", text: $volumeMl)
                    }
                }
                
                Section {
                    DatePicker(
                        "Tanggal Buka / Beli",
                        selection: $openedDate,
                        in: ...Date(),
                        displayedComponents: [.date]
                    )
                    Stepper("Batas Masa Simpan: \(maxDays) Hari", value: $maxDays, in: 30...365, step: 15)
                } header: {
                    Text("Riwayat & Usia Liquid")
                } footer: {
                    Text("Liquid botol terbuka umumnya disarankan dihabiskan dalam 30 - 90 hari untuk profil rasa dan nikotin optimal.")
                }
            }
            .navigationTitle(liquid == nil ? "Tambah Liquid" : "Ubah Liquid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") {
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
