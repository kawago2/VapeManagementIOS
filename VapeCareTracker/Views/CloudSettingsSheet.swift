import SwiftUI

struct CloudSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var syncService = TursoSyncService.shared
    
    @State private var tokenInput: String = TursoConfig.authToken
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isTestingConnection: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundStyle(Color(red: 0.05, green: 0.25, blue: 0.5))
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Turso Cloud SQLite")
                                .font(.headline)
                            Text("Database Serverless Gratis")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Database Endpoint:")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                        Text(TursoConfig.databaseURL)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } header: {
                    Text("Konfigurasi Server")
                }
                
                Section {
                    SecureField("Paste Auth Token Turso di sini...", text: $tokenInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !tokenInput.isEmpty {
                        Button {
                            tokenInput = ""
                            syncService.updateAuthToken("")
                        } label: {
                            Text("Hapus Token")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Auth Token")
                } footer: {
                    Text("Token didapat dari tombol '+ Create Token' di dashboard Turso Anda.")
                }
                
                Section {
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .padding(.trailing, 6)
                            }
                            Text("Simpan & Tes Koneksi")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTestingConnection)
                    
                    if let status = syncService.lastSyncStatus {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Pengaturan Cloud")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Selesai") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .alert("Koneksi Turso", isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func testConnection() {
        let cleanToken = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        syncService.updateAuthToken(cleanToken)
        isTestingConnection = true
        
        Task {
            do {
                try await syncService.initializeTables()
                isTestingConnection = false
                alertMessage = "Koneksi Berhasil! Database Turso sudah terhubung dan tabel siap digunakan."
                showAlert = true
            } catch {
                isTestingConnection = false
                alertMessage = "Gagal terhubung ke Turso: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}
