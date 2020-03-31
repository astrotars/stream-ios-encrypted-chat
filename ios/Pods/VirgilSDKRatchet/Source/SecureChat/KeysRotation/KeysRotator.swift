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
import VirgilCryptoRatchet
import VirgilCrypto

/// KeysRotator errors
///
/// - concurrentRotation: concurrent rotation is not allowed
@objc(VSRKeysRotatorError) public enum KeysRotatorError: Int, LocalizedError {
    case concurrentRotation = 1

    /// Human-readable localized description
    public var errorDescription: String? {
        switch self {
        case .concurrentRotation:
            return "Concurrent rotation is not allowed"
        }
    }
}

/// Default implementation of `KeysRotatorProtocol`
@objc(VSRKeysRotator) public class KeysRotator: NSObject, KeysRotatorProtocol {
    private let crypto: VirgilCrypto
    private let identityPrivateKey: VirgilPrivateKey
    private let identityCardId: String
    private let orphanedOneTimeKeyTtl: TimeInterval
    private let longTermKeyTtl: TimeInterval
    private let outdatedLongTermKeyTtl: TimeInterval
    private let desiredNumberOfOneTimeKeys: Int
    private let longTermKeysStorage: LongTermKeysStorage
    private let oneTimeKeysStorage: OneTimeKeysStorage
    private let client: RatchetClientProtocol
    private let mutex = Mutex()
    private let keyId = RatchetKeyId()

    /// Initializer
    ///
    /// - Parameters:
    ///   - crypto: VirgilCrypto instance
    ///   - identityPrivateKey: identity private key
    ///   - identityCardId: identity card id
    ///   - orphanedOneTimeKeyTtl: time that one-time key lives in the storage after been marked as orphaned. Seconds
    ///   - longTermKeyTtl: time that long-term key is been used before rotation. Seconds
    ///   - outdatedLongTermKeyTtl: time that long-term key lives in the storage after been marked as outdated. Seconds
    ///   - desiredNumberOfOneTimeKeys: desired number of one-time keys
    ///   - longTermKeysStorage: long-term keys storage
    ///   - oneTimeKeysStorage: one-time keys storage
    ///   - client: [RatchetClient](x-source-tag://RatchetClient)
    @objc public init(crypto: VirgilCrypto,
                      identityPrivateKey: VirgilPrivateKey,
                      identityCardId: String,
                      orphanedOneTimeKeyTtl: TimeInterval,
                      longTermKeyTtl: TimeInterval,
                      outdatedLongTermKeyTtl: TimeInterval,
                      desiredNumberOfOneTimeKeys: Int,
                      longTermKeysStorage: LongTermKeysStorage,
                      oneTimeKeysStorage: OneTimeKeysStorage,
                      client: RatchetClientProtocol) {
        self.crypto = crypto
        self.identityPrivateKey = identityPrivateKey
        self.identityCardId = identityCardId
        self.orphanedOneTimeKeyTtl = orphanedOneTimeKeyTtl
        self.longTermKeyTtl = longTermKeyTtl
        self.outdatedLongTermKeyTtl = outdatedLongTermKeyTtl
        self.desiredNumberOfOneTimeKeys = desiredNumberOfOneTimeKeys
        self.longTermKeysStorage = longTermKeysStorage
        self.oneTimeKeysStorage = oneTimeKeysStorage
        self.client = client

        super.init()
    }

    /// Rotates keys
    ///
    /// Rotation process:
    ///   - Retrieve all one-time keys
    ///   - Delete one-time keys that were marked as orphaned more than orphanedOneTimeKeyTtl seconds ago
    ///   - Retrieve all long-term keys
    ///   - Delete long-term keys that were marked as outdated more than outdatedLongTermKeyTtl seconds ago
    ///   - Check that all relevant long-term and one-time keys are in the cloud
    ///     (still persistent in the cloud and were not used)
    ///   - Mark used one-time keys as used
    ///   - Decide on long-term key roration
    ///   - Generate needed number of one-time keys
    ///   - Upload keys to the cloud
    ///
    /// - Returns: GenericOperation
    public func rotateKeysOperation() -> GenericOperation<RotationLog> {
        return CallbackOperation { _, completion in
            guard self.mutex.trylock() else {
                Log.debug("Interrupted concurrent keys' rotation")

                completion(nil, KeysRotatorError.concurrentRotation)
                return
            }

            Log.debug("Started keys' rotation operation")

            var interactionStarted = false

            let completionWrapper: (RotationLog?, Error?) -> Void = {
                do {
                    try self.mutex.unlock()
                }
                catch {
                    completion(nil, error)
                    return
                }

                if interactionStarted {
                    do {
                        try self.oneTimeKeysStorage.stopInteraction()
                    }
                    catch {
                        Log.debug("Completed keys' rotation with storage error")
                        completion(nil, error)
                        return
                    }
                }

                if let error = $1 {
                    Log.debug("Completed keys' rotation with error \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }
                else if let res = $0 {
                    Log.debug("Completed keys' rotation successfully with stats: \(res)")
                    completion(res, nil)
                    return
                }

                fatalError("completionWrapper did not call completion handler")
            }

            do {
                let now = Date()

                let rotationLog = RotationLog()

                try self.oneTimeKeysStorage.startInteraction()
                interactionStarted = true

                let oneTimeKeys = try self.oneTimeKeysStorage.retrieveAllKeys()
                var oneTimeKeysIds = [Data]()
                oneTimeKeysIds.reserveCapacity(oneTimeKeys.count)
                for oneTimeKey in oneTimeKeys {
                    if let orphanedFrom = oneTimeKey.orphanedFrom {
                        if orphanedFrom + self.orphanedOneTimeKeyTtl < now {
                            Log.debug("Removing orphaned one-time key \(oneTimeKey.identifier.hexEncodedString())")
                            try self.oneTimeKeysStorage.deleteKey(withId: oneTimeKey.identifier)
                            rotationLog.oneTimeKeysDeleted += 1
                        }
                        else {
                            rotationLog.oneTimeKeysOrphaned += 1
                        }
                    }
                    else {
                        oneTimeKeysIds.append(oneTimeKey.identifier)
                    }
                }

                var numOfRelevantLongTermKeys = 0
                let longTermKeys = try self.longTermKeysStorage.retrieveAllKeys()
                var lastLongTermKey: LongTermKey? = nil
                for longTermKey in longTermKeys {
                    if let oudatedFrom = longTermKey.outdatedFrom {
                        if oudatedFrom + self.outdatedLongTermKeyTtl < now {
                            Log.debug("Removing outdated long-term key \(longTermKey.identifier.hexEncodedString())")
                            try self.longTermKeysStorage.deleteKey(withId: longTermKey.identifier)
                            rotationLog.longTermKeysDeleted += 1
                        }
                        else {
                            rotationLog.longTermKeysOutdated += 1
                        }
                    }
                    else {
                        if longTermKey.creationDate + self.longTermKeyTtl < now {
                            Log.debug("Marking long-term key as outdated \(longTermKey.identifier.hexEncodedString())")
                            try self.longTermKeysStorage.markKeyOutdated(startingFrom: now,
                                                                         keyId: longTermKey.identifier)
                            rotationLog.longTermKeysMarkedOutdated += 1
                            rotationLog.longTermKeysOutdated += 1
                        }
                        else {
                            if let key = lastLongTermKey, key.creationDate < longTermKey.creationDate {
                                lastLongTermKey = longTermKey
                            }
                            if lastLongTermKey == nil {
                                lastLongTermKey = longTermKey
                            }

                            numOfRelevantLongTermKeys += 1
                        }
                    }
                }

                Log.debug("Validating local keys")
                let validateResponse = try self.client.validatePublicKeys(longTermKeyId: lastLongTermKey?.identifier,
                                                                          oneTimeKeysIds: oneTimeKeysIds)

                for usedOneTimeKeyId in validateResponse.usedOneTimeKeysIds {
                    Log.debug("Marking one-time key as orhpaned \(usedOneTimeKeyId.hexEncodedString())")
                    try self.oneTimeKeysStorage.markKeyOrphaned(startingFrom: now, keyId: usedOneTimeKeyId)
                    rotationLog.oneTimeKeysMarkedOrphaned += 1
                    rotationLog.oneTimeKeysOrphaned += 1
                }

                var rotateLongTermKey = false
                if validateResponse.usedLongTermKeyId != nil || lastLongTermKey == nil {
                    rotateLongTermKey = true
                }
                if let lastLongTermKey = lastLongTermKey, lastLongTermKey.creationDate + self.longTermKeyTtl < now {
                    rotateLongTermKey = true
                }

                let longTermSignedPublicKey: SignedPublicKey?
                if rotateLongTermKey {
                    Log.debug("Rotating long-term key")
                    let longTermKeyPair = try self.crypto.generateKeyPair(ofType: .curve25519)
                    let longTermPrivateKey = try self.crypto.exportPrivateKey(longTermKeyPair.privateKey)
                    let longTermPublicKey = try self.crypto.exportPublicKey(longTermKeyPair.publicKey)
                    let longTermKeyId = try self.keyId.computePublicKeyId(publicKey: longTermPublicKey)
                    _ = try self.longTermKeysStorage.storeKey(longTermPrivateKey,
                                                              withId: longTermKeyId)
                    let longTermKeySignature = try self.crypto.generateSignature(of: longTermPublicKey,
                                                                                 using: self.identityPrivateKey)
                    longTermSignedPublicKey = SignedPublicKey(publicKey: longTermPublicKey,
                                                              signature: longTermKeySignature)
                }
                else {
                    longTermSignedPublicKey = nil
                }

                let numOfRelevantOneTimeKeys = oneTimeKeysIds.count - validateResponse.usedOneTimeKeysIds.count
                let numbOfOneTimeKeysToGen = UInt(max(self.desiredNumberOfOneTimeKeys - numOfRelevantOneTimeKeys, 0))

                Log.debug("Generating \(numbOfOneTimeKeysToGen) one-time keys")
                let oneTimePublicKeys: [Data]
                if numbOfOneTimeKeysToGen > 0 {
                    var publicKeys = [Data]()
                    publicKeys.reserveCapacity(Int(numbOfOneTimeKeysToGen))
                    for _ in 0..<numbOfOneTimeKeysToGen {
                        let keyPair = try self.crypto.generateKeyPair(ofType: .curve25519)
                        let oneTimePrivateKey = try self.crypto.exportPrivateKey(keyPair.privateKey)
                        let oneTimePublicKey = try self.crypto.exportPublicKey(keyPair.publicKey)
                        let keyId = try self.keyId.computePublicKeyId(publicKey: oneTimePublicKey)
                        _ = try self.oneTimeKeysStorage.storeKey(oneTimePrivateKey, withId: keyId)

                        publicKeys.append(oneTimePublicKey)
                    }

                    oneTimePublicKeys = publicKeys
                }
                else {
                    oneTimePublicKeys = []
                }

                Log.debug("Uploading keys")
                try self.client.uploadPublicKeys(identityCardId: self.identityCardId,
                                                 longTermPublicKey: longTermSignedPublicKey,
                                                 oneTimePublicKeys: oneTimePublicKeys)

                rotationLog.oneTimeKeysAdded = oneTimePublicKeys.count
                rotationLog.oneTimeKeysRelevant = numOfRelevantOneTimeKeys + oneTimePublicKeys.count
                rotationLog.longTermKeysRelevant = numOfRelevantLongTermKeys + (longTermSignedPublicKey == nil ? 0 : 1)
                rotationLog.longTermKeysAdded = longTermSignedPublicKey == nil ? 0 : 1

                completionWrapper(rotationLog, nil)
            }
            catch {
                completionWrapper(nil, error)
            }
        }
    }
}
