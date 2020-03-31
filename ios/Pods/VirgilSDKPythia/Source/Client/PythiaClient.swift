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
@objc(VSYPythiaClientError) public enum PythiaClientError: Int, LocalizedError {
    case constructingUrl = 1

    /// Human-readable localized description
    public var errorDescription: String? {
        switch self {
        case .constructingUrl:
            return "Constructing url of endpoint failed"
        }
    }
}

/// Represent card service error
@objc(VSYPythiaServiceError) public final class PythiaServiceError: NSObject, CustomNSError {
    /// Http status code
    @objc public let httpStatusCode: Int
    /// Recieved and decoded `RawServiceError`
    @objc public let rawServiceError: RawServiceError

    /// Initializer
    ///
    /// - Parameter rawServiceError: recieved and decoded rawServiceError
    @objc public init(httpStatusCode: Int, rawServiceError: RawServiceError) {
        self.httpStatusCode = httpStatusCode
        self.rawServiceError = rawServiceError
    }

    /// Error domain or Error instances thrown from Service
    @objc public static var errorDomain: String { return PythiaClient.serviceErrorDomain }
    /// Code of error
    @objc public var errorCode: Int { return self.rawServiceError.code }
    /// Provides info about the error. Error message can be recieve by NSLocalizedDescriptionKey
    @objc public var errorUserInfo: [String: Any] { return [NSLocalizedDescriptionKey: self.rawServiceError.message] }
}

/// Class representing operations with Virgil Cards service
@objc(VSYPythiaClient) open class PythiaClient: BaseClient {
    // swiftlint:disable force_unwrapping
    /// Default URL for service
    @objc public static let defaultURL = URL(string: "https://api.virgilsecurity.com")!
    // swiftlint:enable force_unwrapping
    /// Error domain for Error instances thrown from service
    @objc override open class var serviceErrorDomain: String { return "VirgilSDK.PythiaServiceErrorDomain" }

    internal let retryConfig: ExpBackoffRetry.Config

    /// Initializes new `PythiaClient` instance
    ///
    /// - Parameter accessTokenProvider: Access Token Provider
    @objc public convenience init(accessTokenProvider: AccessTokenProvider) {
        self.init(accessTokenProvider: accessTokenProvider, serviceUrl: CardClient.defaultURL)
    }

    /// Initializes new `PythiaClient` instance
    ///
    /// - Parameters:
    ///   - accessTokenProvider: Access Token Provider
    ///   - serviceUrl: service URL
    @objc public convenience init(accessTokenProvider: AccessTokenProvider, serviceUrl: URL) {
        self.init(accessTokenProvider: accessTokenProvider,
                  serviceUrl: serviceUrl,
                  retryConfig: ExpBackoffRetry.Config())
    }

    /// Initializes new `PythiaClient` instance
    ///
    /// - Parameters:
    ///   - accessTokenProvider: Access Token Provider
    ///   - serviceUrl: service URL
    ///   - requestRetryConfig: Retry config
    public init(accessTokenProvider: AccessTokenProvider,
                serviceUrl: URL,
                connection: HttpConnectionProtocol? = nil,
                retryConfig: ExpBackoffRetry.Config) {
        let version = VersionUtils.getVersion(bundleIdentitifer: "com.virgilsecurity.VirgilSDKPythia")

        let connection = connection ??
            HttpConnection(adapters: [VirgilAgentAdapter(product: "brainkey", version: version)])

        self.retryConfig = retryConfig

        super.init(accessTokenProvider: accessTokenProvider,
                   serviceUrl: serviceUrl,
                   connection: connection)
    }
}
