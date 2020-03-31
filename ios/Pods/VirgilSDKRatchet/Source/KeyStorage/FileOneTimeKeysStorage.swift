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

import Foundation
import VirgilCrypto
import VirgilSDK

/// FileOneTimeKeysStorage errors
///
/// - keyAlreadyExists: This key already exists
/// - keyNotFound: Key not found
/// - keyAlreadyMarked: Key is already marked as orphaned
@objc(VSRFileOneTimeKeysStorageError) public enum FileOneTimeKeysStorageError: Int, LocalizedError {
    case keyAlreadyExists = 1
    case keyNotFound = 2
    case keyAlreadyMarked = 3

    /// Human-readable localized description
    public var errorDescription: String {
        switch self {
        case .keyAlreadyExists:
            return "This key already exists"
        case .keyNotFound:
            return "Key not found"
        case .keyAlreadyMarked:
            return "Key is already marked as orphaned"
        }
    }
}

/// One-time keys storage using file
/// - Note: This class is thread-safe
@objc(VSRFileOneTimeKeysStorage) open class FileOneTimeKeysStorage: NSObject, OneTimeKeysStorage {
    private var oneTimeKeys: OneTimeKeys?
    private let fileSystem: FileSystem

    private struct OneTimeKeys: Codable {
        internal var oneTimeKeys: [OneTimeKey]
    }

    /// Initializer
    ///
    /// - Parameter identity: identity of this user
    @objc public init(identity: String, crypto: VirgilCrypto, identityKeyPair: VirgilKeyPair) {
        let credentials = FileSystemCredentials(crypto: crypto, keyPair: identityKeyPair)
        self.fileSystem = FileSystem(prefix: "VIRGIL-RATCHET",
                                     userIdentifier: identity,
                                     pathComponents: [],
                                     credentials: credentials)

        super.init()
    }

    private let queue = DispatchQueue(label: "FileOneTimeKeysStorageQueue")
    private var interactionCounter = 0

    /// Starts interaction with storage
    /// - Important: This method should be called before any other interaction with storage
    /// - Note: This method can be called many times and works like a stack
    ///
    /// - Throws:
    ///   - Rethrows from `PropertyListDecoder`
    ///   - Rethrows from [FileSystem](x-source-tag://FileSystem)
    @objc public func startInteraction() throws {
        try self.queue.sync {
            if self.interactionCounter > 0 {
                self.interactionCounter += 1
                return
            }

            guard self.oneTimeKeys == nil else {
                fatalError("oneTimeKeys should be nil")
            }

            let data = try self.fileSystem.read(name: "OTK")

            if !data.isEmpty {
                self.oneTimeKeys = try PropertyListDecoder().decode(OneTimeKeys.self, from: data)
            }
            else {
                self.oneTimeKeys = OneTimeKeys(oneTimeKeys: [])
            }

            self.interactionCounter = 1
        }
    }

    /// Stops interaction with storage
    /// - Important: This method should be called after all interactions with storage
    /// - Note: This method can be called many times and works like a stack
    ///
    /// - Throws:
    ///   - Rethrows from `PropertyListEncoder`
    ///   - Rethrows from [FileSystem](x-source-tag://FileSystem)
    @objc public func stopInteraction() throws {
        try self.queue.sync {
            guard self.interactionCounter > 0 else {
                fatalError("interactionCounter should be > 0")
            }

            self.interactionCounter -= 1

            if self.interactionCounter > 0 {
                return
            }

            guard let oneTimeKeys = self.oneTimeKeys else {
                fatalError("oneTimeKeys should not be nil")
            }

            let data = try PropertyListEncoder().encode(oneTimeKeys)

            try self.fileSystem.write(data: data, name: "OTK")

            self.oneTimeKeys = nil
        }
    }

    /// Stores key
    /// - Important: Should be called inside startInteraction/stopInteraction scope
    ///
    /// - Parameters:
    ///   - key: private key
    ///   - id: key id
    /// - Returns: One-time private key
    /// - Throws: `FileOneTimeKeysStorageError.keyAlreadyExists`
    @objc public func storeKey(_ key: Data, withId id: Data) throws -> OneTimeKey {
        return try self.queue.sync {
            guard var oneTimeKeys = self.oneTimeKeys else {
                fatalError("oneTimeKeys should not be nil")
            }

            guard !oneTimeKeys.oneTimeKeys.map({ $0.identifier }).contains(id) else {
                throw FileOneTimeKeysStorageError.keyAlreadyExists
            }

            let oneTimeKey = OneTimeKey(identifier: id, key: key, orphanedFrom: nil)
            oneTimeKeys.oneTimeKeys.append(oneTimeKey)
            self.oneTimeKeys = oneTimeKeys

            return oneTimeKey
        }
    }

    /// Retrieves key
    /// - Important: Should be called inside startInteraction/stopInteraction scope
    ///
    /// - Parameter id: key id
    /// - Returns: One-time private key
    /// - Throws: `FileOneTimeKeysStorageError.keyNotFound`
    @objc public func retrieveKey(withId id: Data) throws -> OneTimeKey {
        guard let oneTimeKeys = self.oneTimeKeys else {
            fatalError("oneTimeKeys should not be nil")
        }

        guard let oneTimeKey = oneTimeKeys.oneTimeKeys.first(where: { $0.identifier == id }) else {
            throw FileOneTimeKeysStorageError.keyNotFound
        }

        return oneTimeKey
    }

    /// Deletes key
    /// - Important: Should be called inside startInteraction/stopInteraction scope
    ///
    /// - Parameter id: key id
    /// - Throws: `FileOneTimeKeysStorageError.keyNotFound`
    @objc public func deleteKey(withId id: Data) throws {
        try self.queue.sync {
            guard var oneTimeKeys = self.oneTimeKeys else {
                fatalError("oneTimeKeys should not be nil")
            }

            guard let index = oneTimeKeys.oneTimeKeys.firstIndex(where: { $0.identifier == id }) else {
                throw FileOneTimeKeysStorageError.keyNotFound
            }

            oneTimeKeys.oneTimeKeys.remove(at: index)
            self.oneTimeKeys = oneTimeKeys
        }
    }

    /// Retrieves all keys
    /// - Important: Should be called inside startInteraction/stopInteraction scope
    ///
    /// - Returns: Returns all keys
    /// - Throws: Doesn't throw
    @objc public func retrieveAllKeys() throws -> [OneTimeKey] {
        guard let oneTimeKeys = self.oneTimeKeys else {
            fatalError("oneTimeKeys should not be nil")
        }

        return oneTimeKeys.oneTimeKeys
    }

    /// Marks key as orphaned
    /// - Important: Should be called inside startInteraction/stopInteraction scope
    ///
    /// - Parameters:
    ///   - date: date from which we found out that this key is orphaned
    ///   - keyId: key id
    /// - Throws:
    ///   - `FileOneTimeKeysStorageError.keyNotFound`
    ///   - `FileOneTimeKeysStorageError.keyAlreadyMarked`
    @objc public func markKeyOrphaned(startingFrom date: Date, keyId: Data) throws {
        try self.queue.sync {
            guard var oneTimeKeys = self.oneTimeKeys else {
                fatalError("oneTimeKeys should not be nil")
            }

            guard let index = oneTimeKeys.oneTimeKeys.firstIndex(where: { $0.identifier == keyId }) else {
                throw FileOneTimeKeysStorageError.keyNotFound
            }

            let oneTimeKey = oneTimeKeys.oneTimeKeys[index]

            guard oneTimeKey.orphanedFrom == nil else {
                throw FileOneTimeKeysStorageError.keyAlreadyMarked
            }

            oneTimeKeys.oneTimeKeys[index] = OneTimeKey(identifier: oneTimeKey.identifier,
                                                        key: oneTimeKey.key,
                                                        orphanedFrom: date)
            self.oneTimeKeys = oneTimeKeys
        }
    }

    /// Deletes all keys
    /// - Important: Should be called after out of startInteraction/stopInteraction scope
    ///
    /// - Throws: Rethrows from [FileSystem](x-source-tag://FileSystem)
    @objc public func reset() throws {
        guard self.interactionCounter == 0 else {
            fatalError("interactionCounter should be 0")
        }

        try self.fileSystem.delete()
    }
}
