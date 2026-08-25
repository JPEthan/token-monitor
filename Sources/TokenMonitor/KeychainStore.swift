import Foundation
import Security

enum KeychainStore {
    private static let service = "local.codex.TokenMonitor"
    private static let legacyServices = ["local.codex.GPTTokenMonitor"]
    private static let account = "OpenAIAdminAPIKey"

    static func loadAPIKey() throws -> String? {
        if let value = try loadValue(service: service) {
            return value
        }

        for legacyService in legacyServices {
            guard let value = try loadValue(service: legacyService) else { continue }
            try saveAPIKey(value)
            try deleteItem(service: legacyService)
            return value
        }

        return nil
    }

    private static func loadValue(service: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainError(status: status)
        }
        guard
            let data = item as? Data,
            let value = String(data: data, encoding: .utf8)
        else {
            throw KeychainError.invalidData
        }

        // Normalize credentials saved by older builds before returning them.
        let migrationLookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let migrationUpdate: [String: Any] = [
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        let migrationStatus = SecItemUpdate(
            migrationLookup as CFDictionary,
            migrationUpdate as CFDictionary
        )
        guard migrationStatus == errSecSuccess else {
            throw KeychainError(status: migrationStatus)
        }

        return value
    }

    static func saveAPIKey(_ value: String) throws {
        let data = Data(value.utf8)
        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let update: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let updateStatus = SecItemUpdate(lookup as CFDictionary, update as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainError(status: updateStatus)
        }

        var newItem = lookup
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        let addStatus = SecItemAdd(newItem as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError(status: addStatus)
        }
    }

    static func deleteAPIKey() throws {
        try deleteItem(service: service)
        for legacyService in legacyServices {
            try deleteItem(service: legacyService)
        }
    }

    private static func deleteItem(service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }
}

enum KeychainError: LocalizedError {
    case invalidData
    case status(OSStatus)

    init(status: OSStatus) {
        self = .status(status)
    }

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Keychain 中的金鑰資料格式無效。"
        case .status(let status):
            let message = SecCopyErrorMessageString(status, nil) as String? ?? "未知錯誤"
            return "Keychain 錯誤：\(message)（\(status)）"
        }
    }
}
