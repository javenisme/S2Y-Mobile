import Foundation

public protocol SecureStore {
    func set(_ data: Data, for key: String) throws
    func get(_ key: String) throws -> Data?
    func remove(_ key: String) throws
}

public final class MemorySecureStore: SecureStore {
    private var storage: [String: Data] = [:]
    public init() {}
    public func set(_ data: Data, for key: String) throws { storage[key] = data }
    public func get(_ key: String) throws -> Data? { storage[key] }
    public func remove(_ key: String) throws { storage.removeValue(forKey: key) }
}

#if canImport(Security) && !os(Linux)
import Security

public final class KeychainSecureStore: SecureStore {
    public init() {}

    public func set(_ data: Data, for key: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key]
        SecItemDelete(query as CFDictionary)
        let add: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                  kSecAttrAccount as String: key,
                                  kSecValueData as String: data]
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    public func get(_ key: String) throws -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnData as String: kCFBooleanTrue as Any]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
        return result as? Data
    }

    public func remove(_ key: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrAccount as String: key]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }
}
#endif

