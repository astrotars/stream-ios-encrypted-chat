//
// Copyright (C) 2015-2019 Virgil Security Inc.
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     (1) Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//
//     (2) Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in
//     the documentation and/or other materials provided with the
//     distribution.
//
//     (3) Neither the name of the copyright holder nor the names of its
//     contributors may be used to endorse or promote products derived from
//     this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
// IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Lead Maintainer: Virgil Security Inc. <support@virgilsecurity.com>
//

import VirgilSDK

/// KeychainLongTermKeysStorage errors
///
/// - invalidKeyId: Invalid key id
/// - invalidMeta: Invalid key meta
@objc(VSRKeychainLongTermKeysStorageError) public enum KeychainLongTermKeysStorageError: Int, LocalizedError {
    case invalidKeyId = 1
    case invalidMeta = 2

    /// Human-readable localized description
    public var errorDescription: String {
        switch self {
        case .invalidKeyId:
            return "Invalid key id"
        case .invalidMeta:
            return "Invalid key meta"
        }
    }
}

/// Long-term keys storage
@objc(VSRKeychainLongTermKeysStorage) open class KeychainLongTermKeysStorage: NSObject, LongTermKeysStorage {
    private let keychain: SandboxedKeychainStorage

    /// Initializer
    ///
    /// - Parameters:
    ///   - identity: identity of this user
    ///   - params: optional custom parameters for KeychainStorage setup
    /// - Throws: Rethrows from `KeychainStorageParams`
    @objc public init(identity: String, params: KeychainStorageParams? = nil) throws {
        let storageParams = try params ?? KeychainStorageParams.makeKeychainStorageParams()

        let keychainStorage = KeychainStorage(storageParams: storageParams)
        self.keychain = SandboxedKeychainStorage(identity: identity,
                                                 prefix: "LTK",
                                                 keychainStorage: keychainStorage)

        super.init()
    }

    private static let outdatedKey = "OD"

    private func makeMeta(outdated: Date) -> [String: String] {
        return [KeychainLongTermKeysStorage.outdatedKey: String(Int(outdated.timeIntervalSince1970))]
    }

    private func parseMeta(_ meta: [String: String]?) -> Date? {
        guard let meta = meta,
            let dateStr = meta[KeychainLongTermKeysStorage.outdatedKey],
            let dateTimestamp = Int(dateStr) else {
                return nil
        }

        return Date(timeIntervalSince1970: TimeInterval(dateTimestamp))
    }

    private func mapEntry(_ entry: KeychainEntry) throws -> LongTermKey {
        guard let id = Data(base64Encoded: entry.name) else {
            throw KeychainLongTermKeysStorageError.invalidKeyId
        }

        return LongTermKey(identifier: id,
                           key: entry.data,
                           creationDate: entry.creationDate,
                           outdatedFrom: self.parseMeta(entry.meta))
    }

    /// Stores key
    ///
    /// - Parameters:
    ///   - key: private key
    ///   - id: key id
    /// - Returns: LongTermKey
    /// - Throws:
    ///   - `KeychainLongTermKeysStorageError.invalidKeyId`
    ///   - Rethrows from `SandboxedKeychainStorage`
    @objc public func storeKey(_ key: Data, withId id: Data) throws -> LongTermKey {
        let entry = try self.keychain.store(data: key, withName: id.base64EncodedString(), meta: [:])

        return try self.mapEntry(entry)
    }

    /// Retrieves key
    ///
    /// - Parameter id: key id
    /// - Returns: Long-term key
    /// - Throws:
    ///   - `KeychainLongTermKeysStorageError.invalidKeyId`
    ///   - Rethrows from `SandboxedKeychainStorage`
    @objc public func retrieveKey(withId id: Data) throws -> LongTermKey {
        let entry = try self.keychain.retrieveEntry(withName: id.base64EncodedString())

        return try self.mapEntry(entry)
    }

    /// Deletes key
    ///
    /// - Parameter id: key id
    /// - Throws: Rethrows from `SandboxedKeychainStorage`
    @objc public func deleteKey(withId id: Data) throws {
        try self.keychain.deleteEntry(withName: id.base64EncodedString())
    }

    /// Retrieves all persistent long-term keys
    ///
    /// - Returns: Long-term keys list
    /// - Throws:
    ///   - `KeychainLongTermKeysStorageError.invalidKeyId`
    ///   - Rethrows from `SandboxedKeychainStorage`
    @objc public func retrieveAllKeys() throws -> [LongTermKey] {
        return try self.keychain.retrieveAllEntries().map(self.mapEntry)
    }

    /// Marks key as outdated
    ///
    /// - Parameters:
    ///   - date: date from which this key started to be outdated
    ///   - keyId: key id
    /// - Throws:
    ///   - `KeychainLongTermKeysStorageError.invalidMeta`
    ///   - Rethrows from `SandboxedKeychainStorage`
    @objc public func markKeyOutdated(startingFrom date: Date, keyId: Data) throws {
        let entry = try self.keychain.retrieveEntry(withName: keyId.base64EncodedString())

        guard self.parseMeta(entry.meta) == nil else {
            throw KeychainLongTermKeysStorageError.invalidMeta
        }

        try self.keychain.updateEntry(withName: keyId.base64EncodedString(),
                                      data: entry.data,
                                      meta: self.makeMeta(outdated: date))
    }

    /// Deletes all long-term keys
    ///
    /// - Throws: Rethrows from `SandboxedKeychainStorage`
    @objc public func reset() throws {
        let keys = try self.keychain.retrieveAllEntries().map(self.mapEntry)

        for key in keys {
            try self.keychain.deleteEntry(withName: key.identifier.base64EncodedString())
        }
    }
}
