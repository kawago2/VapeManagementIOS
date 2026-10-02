import Foundation
import Network

// MARK: - Offline Queue Item Model
struct OfflineQueueItem: Codable, Identifiable {
    let id: UUID
    let query: String
    let timestamp: Date
    let description: String
    
    init(id: UUID = UUID(), query: String, timestamp: Date = Date(), description: String) {
        self.id = id
        self.query = query
        self.timestamp = timestamp
        self.description = description
    }
}

// MARK: - Offline Queue Protocol
protocol OfflineQueueManagerProtocol: AnyObject {
    var pendingItemsCount: Int { get }
    func enqueue(query: String, description: String)
    func getPendingQueue() -> [OfflineQueueItem]
    func clearQueue()
    func remove(id: UUID)
}

// MARK: - Implementation
final class OfflineQueueManager: OfflineQueueManagerProtocol {
    static let shared = OfflineQueueManager()
    
    private let queueKey = "vape_offline_sync_queue"
    private let userDefaults: UserDefaults
    private let queue = DispatchQueue(label: "com.vapecare.offlinequeue", attributes: .concurrent)
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    var pendingItemsCount: Int {
        getPendingQueue().count
    }
    
    func enqueue(query: String, description: String) {
        queue.async(flags: .barrier) {
            var items = self.loadItems()
            let newItem = OfflineQueueItem(query: query, description: description)
            items.append(newItem)
            self.saveItems(items)
        }
    }
    
    func getPendingQueue() -> [OfflineQueueItem] {
        queue.sync {
            return loadItems()
        }
    }
    
    func clearQueue() {
        queue.async(flags: .barrier) {
            self.userDefaults.removeObject(forKey: self.queueKey)
        }
    }
    
    func remove(id: UUID) {
        queue.async(flags: .barrier) {
            var items = self.loadItems()
            items.removeAll { $0.id == id }
            self.saveItems(items)
        }
    }
    
    private func loadItems() -> [OfflineQueueItem] {
        guard let data = userDefaults.data(forKey: queueKey),
              let items = try? JSONDecoder().decode([OfflineQueueItem].self, from: data) else {
            return []
        }
        return items
    }
    
    private func saveItems(_ items: [OfflineQueueItem]) {
        if let data = try? JSONEncoder().encode(items) {
            userDefaults.set(data, forKey: queueKey)
        }
    }
}
