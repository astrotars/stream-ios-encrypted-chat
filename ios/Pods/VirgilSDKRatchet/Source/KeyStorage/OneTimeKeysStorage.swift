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

/// One-time keys storage
@objc(VSROneTimeKeysStorage) public protocol OneTimeKeysStorage: class {
    /// Starts interaction with storage
    /// - Important: This method should be called before any other interaction with storage
    /// - Note: This method can be called many times and works like a stack
    ///
    /// - Throws: Depends on implementation
    @objc func startInteraction() throws

    /// Stops interaction with storage
    /// This method should be called after all interactions with storage
    /// This method can be called many times and works like a stack
    ///
    /// - Throws: Depends on implementation
    @objc func stopInteraction() throws

    /// Stores key
    ///
    /// - Parameters:
    ///   - key: private key
    ///   - id: key id
    /// - Returns: One-time private key
    /// - Throws: Depends on implementation
    @objc func storeKey(_ key: Data, withId id: Data) throws -> OneTimeKey

    /// Retrieves key
    ///
    /// - Parameter id: key id
    /// - Returns: One-time private key
    /// - Throws: Depends on implementation
    @objc func retrieveKey(withId id: Data) throws -> OneTimeKey

    /// Deletes key
    ///
    /// - Parameter id: key id
    /// - Throws: Depends on implementation
    @objc func deleteKey(withId id: Data) throws

    /// Retrieves all keys
    ///
    /// - Returns: Returns all keys
    /// - Throws: Depends on implementation
    @objc func retrieveAllKeys() throws -> [OneTimeKey]

    /// Marks key as orphaned
    ///
    /// - Parameters:
    ///   - date: date from which we found out that this key is orphaned
    ///   - keyId: key id
    /// - Throws: Depends on implementation
    @objc func markKeyOrphaned(startingFrom date: Date, keyId: Data) throws

    /// Deletes all keys
    ///
    /// - Throws: Depends on implementation
    @objc func reset() throws
}
