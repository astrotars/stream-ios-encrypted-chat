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
import VirgilSDK

/// MARK: - Extension with objective-c methods
public extension SecureChat {
    /// Starts new session with given participant using his identity card
    ///
    /// - Parameters:
    ///   - receiverCard: receiver identity cards
    ///   - name: Session name
    ///   - completion: completion handler
    ///   - session: created [SecureSession](x-source-tag://SecureSession)
    ///   - error: corresponding error
    @objc func startNewSessionAsSender(receiverCard: Card, name: String? = nil,
                                       completion: @escaping (_ session: SecureSession?, _ error: Error?) -> Void) {
        self.startNewSessionAsSender(receiverCard: receiverCard, name: name).start(completion: completion)
    }

    /// Starts multiple new sessions with given participants using their identity cards
    ///
    /// - Parameters:
    ///   - receiverCards: receivers identity cards
    ///   - name: Session name
    ///   - completion: completion handler
    ///   - sessions: array with created [SecureSessions](x-source-tag://SecureSession)
    ///   - error: corresponding error
    @objc func startMultipleNewSessionsAsSender(receiverCards: [Card], name: String? = nil,
                                                completion: @escaping (_ sessions: [SecureSession]?,
                                                                       _ error: Error?) -> Void) {
        self.startMutipleNewSessionsAsSender(receiverCards: receiverCards, name: name).start(completion: completion)
    }

    /// Rotates keys. See rotateKeys() -> GenericOperation<RotationLog> for details
    ///
    /// - Parameters:
    ///   - completion: completion handler
    ///   - rotationLog: represents the result of rotateKeys operation
    ///   - error: corresponding error
    @objc func rotateKeys(completion: @escaping (_ rotationLog: RotationLog?, _ error: Error?) -> Void) {
        self.rotateKeys().start(completion: completion)
    }

    /// Removes all data corresponding to this user: sessions and keys.
    ///
    /// - Parameters:
    ///   - completion: completion handler
    ///   - error: corresponding error
    @objc func reset(completion: @escaping (_ error: Error?) -> Void) {
        self.reset().start { _, error in
            completion(error)
        }
    }
}
