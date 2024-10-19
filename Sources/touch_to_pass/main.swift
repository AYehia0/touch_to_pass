import Foundation
import LocalAuthentication
import SwiftOTP
import ArgumentParser

let policy = LAPolicy.deviceOwnerAuthenticationWithBiometrics
let serviceName = "com.touchtopass.app"  // Unique identifier for the service

struct TouchToPass: ParsableCommand {
    @Argument(help: "The action to perform: get, set, delete")
    var action: String

    @Argument(help: "Keys to get, set, or delete")
    var keys: [String] = []

    @Option(name: .customLong("totp"), parsing: .upToNextOption, help: "Generate TOTP for specified keys")
    var totpKeys: [String] = []

    func run() throws {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 0

        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else {
            print("This Mac doesn't support deviceOwnerAuthenticationWithBiometrics")
            throw ExitCode.failure
        }

        switch action {
        case "get":
            context.evaluatePolicy(policy, localizedReason: "access to your keychain items") { success, error in
                if success && error == nil {
                    var results: [String: String] = [:]

                    // Get all passwords for specified keys
                    for key in keys {
                        if let passwordData = getPasswordData(forKey: key) {
                            results[key] = passwordData
                        }
                    }

                    // Get TOTP codes for specified totpKeys
                    for totpKey in totpKeys {
                        if let secret = getPasswordData(forKey: totpKey) {
                            if let secretData = base32DecodeToData(secret) {
                                let totp = TOTP(secret: secretData, digits: 6, timeInterval: 30, algorithm: .sha1)
                                if let code = totp?.generate(time: Date()) {
                                    results[totpKey] = code
                                } else {
                                    print("Error generating TOTP code for \(totpKey)")
                                }
                            } else {
                                print("Error: Failed to decode base32 secret for key '\(totpKey)'. Ensure the secret is in valid base32 format.")
                            }
                        } else {
                            print("Error: TOTP secret not found for key '\(totpKey)'")
                        }
                    }

                    // Print results as JSON
                    if let jsonData = try? JSONSerialization.data(withJSONObject: results, options: .prettyPrinted),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        print(jsonString)
                    } else {
                        print("Error generating JSON output")
                    }
                } else {
                    let errorDescription = error?.localizedDescription ?? "Unknown error"
                    print("Error: \(errorDescription)")
                }
                Foundation.exit(success ? EXIT_SUCCESS : EXIT_FAILURE)
            }
            dispatchMain()
        case "set":
            if keys.count < 2 {
                print("You must specify exactly one key and one value for the set action.")
                throw ExitCode.failure
            }
            let key = keys[0]
            let password = keys[1]

            context.evaluatePolicy(policy, localizedReason: "set to your password") { success, error in
                if success {
                    guard setPassword(key: key, password: password) else {
                        print("Error setting password")
                        Foundation.exit(EXIT_FAILURE)
                    }
                    print("Key \(key) has been successfully set in the keychain")
                } else {
                    let errorDescription = error?.localizedDescription ?? "Unknown error"
                    print("Error: \(errorDescription)")
                }
                Foundation.exit(success ? EXIT_SUCCESS : EXIT_FAILURE)
            }
            dispatchMain()
        case "delete":
            if keys.isEmpty {
                print("You must specify at least one key for the delete action.")
                throw ExitCode.failure
            }
            let key = keys[0]

            context.evaluatePolicy(policy, localizedReason: "delete your password") { success, error in
                if success {
                    guard deletePassword(key: key) else {
                        print("Error deleting password")
                        Foundation.exit(EXIT_FAILURE)
                    }
                    print("Key \(key) has been successfully deleted from the keychain")
                } else {
                    let errorDescription = error?.localizedDescription ?? "Unknown error"
                    print("Error: \(errorDescription)")
                }
                Foundation.exit(success ? EXIT_SUCCESS : EXIT_FAILURE)
            }
            dispatchMain()
        default:
            print("Invalid action. Use get, set, or delete.")
            throw ExitCode.failure
        }
    }
}

TouchToPass.main()

func getPasswordData(forKey key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecAttrService as String: serviceName,
        kSecReturnData as String: true
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecSuccess, let passwordData = item as? Data,
       let password = String(data: passwordData, encoding: .utf8) {
        return password
    } else {
        if let errorMessage = SecCopyErrorMessageString(status, nil) {
            print("Error getting password data for key '\(key)': \(errorMessage)")
        } else {
            print("Error getting password data for key '\(key)': Unknown error with status code \(status)")
        }
    }
    return nil
}

func setPassword(key: String, password: String) -> Bool {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecAttrService as String: serviceName,  // Add service name to uniquely identify your app's items
        kSecValueData as String: password.data(using: .utf8) ?? Data(),
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    if status == errSecDuplicateItem {
        // Item already exists, update it
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: serviceName
        ]
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: password.data(using: .utf8) ?? Data(),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
        return updateStatus == errSecSuccess
    }
    return status == errSecSuccess
}

func deletePassword(key: String) -> Bool {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecAttrService as String: serviceName  // Add service name to filter deletions to your app's items only
    ]

    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess
}
