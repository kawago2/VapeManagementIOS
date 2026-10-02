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
                            Text(L10n.CloudSettings.serverlessSub)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(L10n.CloudSettings.providerHeader)
                }
                
                Section {
                    TextField("libsql://... or https://...", text: $urlInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    
                    if !urlInput.isEmpty {
                        Button {
                            urlInput = ""
                        } label: {
                            Text(L10n.CloudSettings.clearUrl)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text(L10n.CloudSettings.urlHeader)
                } footer: {
                    Text(L10n.CloudSettings.urlFooter)
                }
                
                Section {
                    SecureField(L10n.CloudSettings.tokenPlaceholder, text: $tokenInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !tokenInput.isEmpty {
                        Button {
                            tokenInput = ""
                        } label: {
                            Text(L10n.CloudSettings.clearToken)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text(L10n.CloudSettings.tokenHeader)
                } footer: {
                    Text(L10n.CloudSettings.tokenFooter)
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
                            Text(L10n.CloudSettings.testButton)
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
                            alertMessage = "Failed to create JSON backup: \(error.localizedDescription)"
                            showAlert = true
                        }
                    } label: {
                        Label(L10n.CloudSettings.exportJson, systemImage: "arrow.down.doc.fill")
                    }
                    
                    Button {
                        do {
                            let url = try viewModel.exportCSV()
                            self.exportURL = url
                        } catch {
                            alertMessage = "Failed to create CSV report: \(error.localizedDescription)"
                            showAlert = true
                        }
                    } label: {
                        Label(L10n.CloudSettings.exportCsv, systemImage: "tablecells.badge.ellipsis")
                    }
                } header: {
                    Text(L10n.CloudSettings.backupHeader)
                } footer: {
                    Text(L10n.CloudSettings.backupFooter)
                }
            }
            .navigationTitle(L10n.CloudSettings.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.done) {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
            .alert(L10n.CloudSettings.alertTitle, isPresented: $showAlert) {
                Button(L10n.Common.ok) {}
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
                // Automatically pull latest data from cloud after connection succeeds
                await viewModel.pullFromCloud(showToast: false)
                isTestingConnection = false
                alertMessage = String(localized: "Connection successful! Database connected and cloud data loaded.")
                showAlert = true
            } catch {
                isTestingConnection = false
                alertMessage = String(localized: "Failed to connect to Turso: \(error.localizedDescription)")
                showAlert = true
            }
        }
    }
}
