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

/// Declares client error types and codes
///
/// - constructingUrl: constructing url of endpoint failed
@objc(VSRRatchetClientError) public enum RatchetClientError: Int, LocalizedError {
    case constructingUrl = 1

    /// Human-readable localized description
    public var errorDescription: String {
        switch self {
        case .constructingUrl:
            return "constructing url of endpoint failed"
        }
    }
}

/// Implemetation of RatchetClientProtocol
/// - Tag: RatchetClient
@objc(VSRRatchetClient) open class RatchetClient: BaseClient {
    // swiftlint:disable force_unwrapping
    /// Default URL for service
    @objc public static let defaultURL = URL(string: "https://api.virgilsecurity.com")!
    // swiftlint:enable force_unwrapping

    internal let retryConfig: ExpBackoffRetry.Config

    /// Initializes a new `RatchetClient` instance
    ///
    /// - Parameters:
    ///   - accessTokenProvider: Access token provider
    ///   - serviceUrl: URL of service client will use
    ///   - connection: custom HTTPConnection
    public init(accessTokenProvider: AccessTokenProvider,
                serviceUrl: URL = RatchetClient.defaultURL,
                connection: HttpConnectionProtocol? = nil,
                retryConfig: ExpBackoffRetry.Config) {
        let version = VersionUtils.getVersion(bundleIdentitifer: "com.virgilsecurity.VirgilSDKRatchet")

        let connection = connection ?? HttpConnection(adapters: [VirgilAgentAdapter(product: "sdk", version: version)])

        self.retryConfig = retryConfig

        super.init(accessTokenProvider: accessTokenProvider,
                   serviceUrl: serviceUrl,
                   connection: connection)
    }

    /// Initializes new `RatchetClient` instance
    ///
    /// - Parameter accessTokenProvider: Access Token Provider
    @objc public convenience init(accessTokenProvider: AccessTokenProvider) {
        self.init(accessTokenProvider: accessTokenProvider, serviceUrl: RatchetClient.defaultURL)
    }

    /// Initializes new `RatchetClient` instance
    ///
    /// - Parameters:
    ///   - accessTokenProvider: Access Token Provider
    ///   - serviceUrl: service URL
    @objc public convenience init(accessTokenProvider: AccessTokenProvider, serviceUrl: URL) {
        self.init(accessTokenProvider: accessTokenProvider,
                  serviceUrl: serviceUrl,
                  retryConfig: ExpBackoffRetry.Config())
    }
}
