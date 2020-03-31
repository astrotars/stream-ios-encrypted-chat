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

// MARK: - Queries
extension RatchetClient: RatchetClientProtocol {
    private func createRetry() -> RetryProtocol {
        return ExpBackoffRetry(config: self.retryConfig)
    }

    /// Uploads public keys
    ///
    /// Long-term public key signature should be verified.
    /// Upload priority: identity card id > long-term public key > one-time public key.
    /// Which means long-term public key can't be uploaded if identity card id is absent in the cloud
    /// and one-time public key can't be uploaded if long-term public key is absent in the cloud.
    ///
    /// - Parameters:
    ///   - identityCardId: Identity cardId that should be available on Card service.
    ///             It's public key should be ED25519
    ///   - longTermPublicKey: long-term public key + its signature created using identity private key.
    ///             Should be curve25519 in PKCS#8
    ///   - oneTimePublicKeys: one-time public keys (up to 150 keys in the cloud).
    ///             Should be curve25519 in PKCS#8
    /// - Throws:
    ///   - `RatchetClientError.constructingUrl`
    ///   - Rethrows from `ServiceRequest`
    ///   - Rethrows from `HttpConnectionProtocol`
    ///   - Rethrows from `JSONDecoder`
    ///   - Rethrows from `BaseClient`
    @objc public func uploadPublicKeys(identityCardId: String?,
                                       longTermPublicKey: SignedPublicKey?,
                                       oneTimePublicKeys: [Data]) throws {
        guard let url = URL(string: "pfs/v2/keys", relativeTo: self.serviceUrl) else {
            throw RatchetClientError.constructingUrl
        }

        var params: [String: Any] = [:]

        if let identityCardId = identityCardId {
            params["identity_card_id"] = identityCardId
        }

        if let longTermPublicKey = longTermPublicKey {
            let longTermPublicKeyParam = [
                "public_key": longTermPublicKey.publicKey.base64EncodedString(),
                "signature": longTermPublicKey.signature.base64EncodedString()
            ]
            params["long_term_key"] = longTermPublicKeyParam
        }

        if !oneTimePublicKeys.isEmpty {
            let oneTimePublicKeysStrings = oneTimePublicKeys.map { $0.base64EncodedString() }
            params["one_time_keys"] = oneTimePublicKeysStrings
        }

        let request = try ServiceRequest(url: url, method: .put, params: params)

        let tokenContext = TokenContext(service: "ratchet", operation: "post")

        let response = try self.sendWithRetry(request, retry: self.createRetry(), tokenContext: tokenContext)
            .startSync()
            .get()

        try self.validateResponse(response)
    }

    /// Checks list of keys ids and returns subset of that list with already used keys ids
    ///
    /// - Note: keyId == SHA512(raw 32-byte publicKey)[0..<8]
    ///
    /// - Parameters:
    ///   - longTermKeyId: long-term public key id to validate
    ///   - oneTimeKeysIds: list of one-time public keys ids to validate
    /// - Returns: Object with used keys ids
    /// - Throws:
    ///   - `RatchetClientError.constructingUrl`
    ///   - Rethrows from `ServiceRequest`
    ///   - Rethrows from `HttpConnectionProtocol`
    ///   - Rethrows from `JSONDecoder`
    ///   - Rethrows from `BaseClient`
    @objc public func validatePublicKeys(longTermKeyId: Data?,
                                         oneTimeKeysIds: [Data]) throws -> ValidatePublicKeysResponse {
        guard longTermKeyId != nil || !oneTimeKeysIds.isEmpty else {
            return ValidatePublicKeysResponse(usedLongTermKeyId: nil, usedOneTimeKeysIds: [])
        }

        guard let url = URL(string: "pfs/v2/keys/actions/validate", relativeTo: self.serviceUrl) else {
            throw RatchetClientError.constructingUrl
        }

        var params: [String: Any] = [:]

        if let longTermKeyId = longTermKeyId {
            params["long_term_key_id"] = longTermKeyId.base64EncodedString()
        }

        if !oneTimeKeysIds.isEmpty {
            params["one_time_keys_ids"] = oneTimeKeysIds.map { $0.base64EncodedString() }
        }

        let request = try ServiceRequest(url: url, method: .post, params: params)

        let tokenContext = TokenContext(service: "ratchet", operation: "get")

        let response = try self.sendWithRetry(request, retry: self.createRetry(), tokenContext: tokenContext)
            .startSync()
            .get()

        return try self.processResponse(response)
    }

    /// Returns public keys set for given identity
    ///
    /// - Parameter identity: User's identity
    /// - Returns: Set of public keys
    /// - Throws:
    ///   - `RatchetClientError.constructingUrl`
    ///   - Rethrows from `ServiceRequest`
    ///   - Rethrows from `HttpConnectionProtocol`
    ///   - Rethrows from `JSONDecoder`
    ///   - Rethrows from `BaseClient`
    @objc public func getPublicKeySet(forRecipientIdentity identity: String) throws -> PublicKeySet {
        guard let url = URL(string: "pfs/v2/keys/actions/pick-one", relativeTo: self.serviceUrl) else {
            throw RatchetClientError.constructingUrl
        }

        let params = ["identity": identity]

        let request = try ServiceRequest(url: url, method: .post, params: params)

        let tokenContext = TokenContext(service: "ratchet", operation: "get")

        let response = try self.sendWithRetry(request, retry: self.createRetry(), tokenContext: tokenContext)
            .startSync()
            .get()

        return try self.processResponse(response)
    }

    /// Returns public keys sets for given identities.
    ///
    /// - Parameter identities: Users' identities
    /// - Returns: Sets of public keys
    /// - Throws:
    ///   - `RatchetClientError.constructingUrl`
    ///   - Rethrows from `ServiceRequest`
    ///   - Rethrows from `HttpConnectionProtocol`
    ///   - Rethrows from `JSONDecoder`
    ///   - Rethrows from `BaseClient`
    @objc public func getMultiplePublicKeysSets(forRecipientsIdentities identities: [String])
        throws -> [IdentityPublicKeySet] {
        guard let url = URL(string: "pfs/v2/keys/actions/pick-batch", relativeTo: self.serviceUrl) else {
            throw RatchetClientError.constructingUrl
        }

        let params = ["identities": identities]

        let request = try ServiceRequest(url: url, method: .post, params: params)

        let tokenContext = TokenContext(service: "ratchet", operation: "get")

        let response = try self.sendWithRetry(request, retry: self.createRetry(), tokenContext: tokenContext)
            .startSync()
            .get()

        return try self.processResponse(response)
    }

    /// Deletes keys entity
    ///
    /// - Throws:
    ///   - `RatchetClientError.constructingUrl`
    ///   - Rethrows from `ServiceRequest`
    ///   - Rethrows from `HttpConnectionProtocol`
    ///   - Rethrows from `JSONDecoder`
    ///   - Rethrows from `BaseClient`
    @objc public func deleteKeysEntity() throws {
        guard let url = URL(string: "pfs/v2/keys", relativeTo: self.serviceUrl) else {
            throw RatchetClientError.constructingUrl
        }

        let request = try ServiceRequest(url: url, method: .delete)

        let tokenContext = TokenContext(service: "ratchet", operation: "delete")

        let response = try self.sendWithRetry(request, retry: self.createRetry(), tokenContext: tokenContext)
            .startSync()
            .get()

        try self.validateResponse(response)
    }
}
