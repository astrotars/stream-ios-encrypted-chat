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

/// Client used to communicate with ratchet service
@objc(VSRRatchetClientProtocol) public protocol RatchetClientProtocol: class {
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
    /// - Throws: Depends on implementation
    @objc func uploadPublicKeys(identityCardId: String?,
                                longTermPublicKey: SignedPublicKey?,
                                oneTimePublicKeys: [Data]) throws

    /// Checks list of keys ids and returns subset of that list with already used keys ids
    ///
    /// - Note: keyId == SHA512(raw 32-byte publicKey)[0..<8]
    ///
    /// - Parameters:
    ///   - longTermKeyId: long-term public key id to validate
    ///   - oneTimeKeysIds: list of one-time public keys ids to validate
    /// - Returns: Object with used keys ids
    /// - Throws: Depends on implementation
    @objc func validatePublicKeys(longTermKeyId: Data?,
                                  oneTimeKeysIds: [Data]) throws -> ValidatePublicKeysResponse

    /// Returns public keys set for given identity.
    ///
    /// - Parameter identity: User's identity
    /// - Returns: Set of public keys
    /// - Throws: Depends on implementation
    @objc func getPublicKeySet(forRecipientIdentity identity: String) throws -> PublicKeySet

    /// Returns public keys sets for given identities.
    ///
    /// - Parameter identities: Users' identities
    /// - Returns: Sets of public keys
    /// - Throws: Depends on implementation
    @objc func getMultiplePublicKeysSets(forRecipientsIdentities identities: [String]) throws -> [IdentityPublicKeySet]

    /// Deletes keys entity
    ///
    /// - Throws: Depends on implementation
    @objc func deleteKeysEntity() throws
}
