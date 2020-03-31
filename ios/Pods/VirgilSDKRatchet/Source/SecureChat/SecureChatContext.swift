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

import VirgilCrypto
import VirgilSDK

/// SecureChat context
/// - Tag: SecureChatContext
@objc(VSRSecureChatContext) open class SecureChatContext: NSObject {

    /// User's identity card id
    @objc public let identityCard: Card

    /// User's identity private key (corresponding to public key in identityCard)
    @objc public let identityPrivateKey: VirgilPrivateKey

    /// Time that one-time key lives in the storage after been marked as orphaned. Seconds
    @objc public var orphanedOneTimeKeyTtl: TimeInterval = 24 * 60 * 60

    /// Time that long-term key is been used before rotation. Seconds
    @objc public var longTermKeyTtl: TimeInterval = 5 * 24 * 60 * 60

    /// Time that long-term key lives in the storage after been marked as outdated. Seconds
    @objc public var outdatedLongTermKeyTtl: TimeInterval = 24 * 60 * 60

    /// Desired number of one-time keys
    @objc public var desiredNumberOfOneTimeKeys: Int = 100

    /// App name, defaults to Bundle.main.bundleIdentifier
    @objc public var appName: String? = nil

    /// Ratchet client
    @objc public var client: RatchetClient

    /// Initializer
    ///
    /// - Parameters:
    ///   - identityCard: user's identity card
    ///   - identityPrivateKey: user's identity private key (corresponding to public key in identityCard)
    ///   - accessTokenProvider: access token provider
    @objc public init(identityCard: Card,
                      identityPrivateKey: VirgilPrivateKey,
                      accessTokenProvider: AccessTokenProvider) {
        self.identityCard = identityCard
        self.identityPrivateKey = identityPrivateKey
        self.client = RatchetClient(accessTokenProvider: accessTokenProvider)

        super.init()
    }
}
