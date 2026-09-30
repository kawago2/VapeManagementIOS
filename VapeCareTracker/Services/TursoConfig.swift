import Foundation

struct TursoConfig {
    // Key used to securely/persistently store your token in UserDefaults if entered via UI
    private static let authTokenKey = "turso_stored_auth_token_key"
    private static let databaseURLKey = "turso_stored_database_url_key"
    
    // Default fallback endpoint (empty unless provided via Secrets.plist or Settings)
    private static let defaultDatabaseURL = ""
    
    // MARK: - Secret Environment Reader
    private static var secretsDict: [String: Any]? = {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        return plist
    }()
    
    // Database URL HTTPS endpoint for Turso libSQL over HTTP
    static var databaseURL: String {
        if let envURL = secretsDict?["TURSO_DATABASE_URL"] as? String,
           !envURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !envURL.contains("YOUR_TURSO_DATABASE_URL") {
            return envURL.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return UserDefaults.standard.string(forKey: databaseURLKey) ?? defaultDatabaseURL
    }
    
    // Auth Token: prioritizes Secrets.plist, then stored UserDefaults
    static var authToken: String {
        get {
            if let envToken = secretsDict?["TURSO_AUTH_TOKEN"] as? String,
               !envToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !envToken.contains("YOUR_TURSO_AUTH_TOKEN") {
                return envToken.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return UserDefaults.standard.string(forKey: authTokenKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: authTokenKey)
        }
    }
    
    static var isConfigured: Bool {
        !authToken.isEmpty
    }
}
