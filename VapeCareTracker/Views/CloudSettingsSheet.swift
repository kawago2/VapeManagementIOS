import SwiftUI

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct CloudSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VapeDashboardViewModel
    @StateObject private var syncService = TursoSyncService.shared
    
    @State private var urlInput: String = TursoConfig.databaseURL
    @State private var tokenInput: String = TursoConfig.authToken
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isTestingConnection: Bool = false
    
    @State private var exportURL: URL? = nil
    @State private var isExporting: Bool = false
    
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
                            Text("Database Serverless Cloud")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Penyedia Cloud")
                }
                
                Section {
                    TextField("libsql://... atau https://...", text: $urlInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    
                    if !urlInput.isEmpty {
                        Button {
                            urlInput = ""
                        } label: {
                            Text("Hapus URL")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Database URL")
                } footer: {
                    Text("Mendukung format 'libsql://...' maupun 'https://...'. Bila menggunakan libsql://, otomatis dikonversi ke protokol HTTPS.")
                }
                
                Section {
                    SecureField("Paste Auth Token Turso...", text: $tokenInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !tokenInput.isEmpty {
                        Button {
                            tokenInput = ""
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
                    .disabled(
                        urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        isTestingConnection
                    )
                    
                    if let status = syncService.lastSyncStatus {
                        HStack(spacing: 8) {
                            Image(systemName: syncService.isConnected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(syncService.isConnected ? .green : .orange)
                            Text(status)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Button {
                        do {
                            let url = try viewModel.exportJSON()
                            self.exportURL = url
                        } catch {
                            alertMessage = "Gagal membuat backup JSON: \(error.localizedDescription)"
                            showAlert = true
                        }
                    } label: {
                        Label("Export Cadangan Lengkap (JSON)", systemImage: "arrow.down.doc.fill")
                    }
                    
                    Button {
                        do {
                            let url = try viewModel.exportCSV()
                            self.exportURL = url
                        } catch {
                            alertMessage = "Gagal membuat laporan CSV: \(error.localizedDescription)"
                            showAlert = true
                        }
                    } label: {
                        Label("Export Laporan Tabel (CSV)", systemImage: "tablecells.badge.ellipsis")
                    }
                } header: {
                    Text("Cadangan & Ekspor Data")
                } footer: {
                    Text("Ekspor data lokal untuk dicadangkan atau dibuka di aplikasi Spreadsheet seperti Excel / Numbers.")
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
            .sheet(item: Binding<IdentifiableURL?>(
                get: { exportURL.map { IdentifiableURL(url: $0) } },
                set: { exportURL = $0?.url }
            )) { identifiableURL in
                ShareSheet(activityItems: [identifiableURL.url])
            }
        }
    }
    
    private func testConnection() {
        let cleanURL = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanToken = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        syncService.updateCredentials(url: cleanURL, token: cleanToken)
        urlInput = TursoConfig.databaseURL // Update displayed URL to normalized form
        isTestingConnection = true
        
        Task {
            do {
                try await syncService.initializeTables()
                // Otomatis tarik data terbaru dari cloud setelah koneksi berhasil
                await viewModel.pullFromCloud(showToast: false)
                isTestingConnection = false
                alertMessage = "Koneksi Berhasil! Database terhubung dan data cloud berhasil dimuat."
                showAlert = true
            } catch {
                isTestingConnection = false
                alertMessage = "Gagal terhubung ke Turso: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}
