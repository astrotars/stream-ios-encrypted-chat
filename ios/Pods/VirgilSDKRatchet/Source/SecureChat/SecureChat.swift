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

/// SecureChat errors
///
/// - sessionAlreadyExists: Session with this participant already exists
/// - wrongIdentityPublicKeyCrypto: PublicKey is not VirgilPublicKey
/// - identityKeyDoesntMatch: Identity key in the Card and on Ratchet Cloud doesn't match
/// - invalidLongTermKeySignature: Long-term key signature is invalid
/// - invalidMessageType: Message type should be .prekey
/// - invalidKeyType: Invalid key type
/// - publicKeysSetsMismatch: PublicKeysSets mismatch
/// - invalidSessionIdLen: Session Id should be 32-byte
/// - invalidCardId: Invalid card id
/// - sessionIdMismatch: Session id mismatch
@objc(VSRSecureChatError) public enum SecureChatError: Int, LocalizedError {
    case sessionAlreadyExists = 1
    case wrongIdentityPublicKeyCrypto = 2
    case identityKeyDoesntMatch = 3
    case invalidLongTermKeySignature = 4
    case invalidMessageType = 5
    case invalidKeyType = 6
    case publicKeysSetsMismatch = 7
    case invalidSessionIdLen = 8
    case invalidCardId = 9
    case sessionIdMismatch = 10

    /// Human-readable localized description
    public var errorDescription: String {
        switch self {
        case .sessionAlreadyExists:
            return "Session with this participant already exists"
        case .wrongIdentityPublicKeyCrypto:
            return "PublicKey is not VirgilPublicKey"
        case .identityKeyDoesntMatch:
            return "Identity key in the Card and on Ratchet Cloud doesn't match"
        case .invalidLongTermKeySignature:
            return "Long-term key signature is invalid"
        case .invalidMessageType:
            return "Message type should be .prekey"
        case .invalidKeyType:
            return "Invalid key type"
        case .publicKeysSetsMismatch:
            return "PublicKeysSets mismatch"
        case .invalidSessionIdLen:
            return "Session Id should be 32-byte"
        case .invalidCardId:
                return "Invalid card id"
        case .sessionIdMismatch:
                return "Session id mismatch"
        }
    }
}

/// SecureChat. Class for rotating keys, starting and responding to conversation
@objc(VSRSecureChat) open class SecureChat: NSObject {
    /// Identity private key
    @objc public let identityPrivateKey: VirgilPrivateKey

    /// Crypto
    @objc public let crypto: VirgilCrypto

    /// Long-term keys storage
    @objc public let longTermKeysStorage: LongTermKeysStorage

    /// One-time keys storage
    @objc public let oneTimeKeysStorage: OneTimeKeysStorage

    /// Session storage
    @objc public let sessionStorage: SessionStorage

    /// Group session storage
    @objc public let groupSessionStorage: GroupSessionStorage

    /// Client
    @objc public let client: RatchetClientProtocol

    // Identity card id
    @objc public let identityCard: Card

    private let keyId = RatchetKeyId()
    private let keysRotator: KeysRotatorProtocol

    /// Default session name (if nil is passed)
    @objc public static let defaultSessionName = "DEFAULT"

    /// Initializer
    ///
    /// - Parameter context: [SecureChatContext](x-source-tag://SecureChatContext)
    /// - Throws:
    ///   - Rethrows from `KeychainLongTermKeysStorage`
    @objc public convenience init(context: SecureChatContext) throws {
        let crypto = try VirgilCrypto()
        let client = context.client

        let params: KeychainStorageParams?
        if let appName = context.appName {
            params = try KeychainStorageParams.makeKeychainStorageParams(appName: appName)
        }
        else {
            params = nil
        }

        let identityKeyPair = VirgilKeyPair(privateKey: context.identityPrivateKey,
                                            publicKey: context.identityCard.publicKey)
        let longTermKeysStorage = try KeychainLongTermKeysStorage(identity: context.identityCard.identity,
                                                                  params: params)
        let oneTimeKeysStorage = FileOneTimeKeysStorage(identity: context.identityCard.identity,
                                                        crypto: crypto,
                                                        identityKeyPair: identityKeyPair)
        let sessionStorage = FileSessionStorage(identity: context.identityCard.identity,
                                                crypto: crypto,
                                                identityKeyPair: identityKeyPair)
        let groupSessionStorage = try FileGroupSessionStorage(identity: context.identityCard.identity,
                                                              crypto: crypto,
                                                              identityKeyPair: identityKeyPair)
        let keysRotator = KeysRotator(crypto: crypto,
                                      identityPrivateKey: context.identityPrivateKey,
                                      identityCardId: context.identityCard.identifier,
                                      orphanedOneTimeKeyTtl: context.orphanedOneTimeKeyTtl,
                                      longTermKeyTtl: context.longTermKeyTtl,
                                      outdatedLongTermKeyTtl: context.outdatedLongTermKeyTtl,
                                      desiredNumberOfOneTimeKeys: context.desiredNumberOfOneTimeKeys,
                                      longTermKeysStorage: longTermKeysStorage,
                                      oneTimeKeysStorage: oneTimeKeysStorage,
                                      client: client)

        self.init(crypto: crypto,
                  identityPrivateKey: context.identityPrivateKey,
                  identityCard: context.identityCard,
                  client: client,
                  longTermKeysStorage: longTermKeysStorage,
                  oneTimeKeysStorage: oneTimeKeysStorage,
                  sessionStorage: sessionStorage,
                  groupSessionStorage: groupSessionStorage,
                  keysRotator: keysRotator)
    }

    /// Initializer
    ///
    /// - Parameters:
    ///   - crypto: VirgilCrypto instance
    ///   - identityPrivateKey: identity private key
    ///   - identityCard: Identity card
    ///   - client: client
    ///   - longTermKeysStorage: long-term keys storage
    ///   - oneTimeKeysStorage: one-time keys storage
    ///   - sessionStorage: session storage
    ///   - groupSessionStorage: group session storage
    ///   - keysRotator: keys rotation
    public init(crypto: VirgilCrypto,
                identityPrivateKey: VirgilPrivateKey,
                identityCard: Card,
                client: RatchetClientProtocol,
                longTermKeysStorage: LongTermKeysStorage,
                oneTimeKeysStorage: OneTimeKeysStorage,
                sessionStorage: SessionStorage,
                groupSessionStorage: GroupSessionStorage,
                keysRotator: KeysRotatorProtocol) {
        self.crypto = crypto
        self.identityPrivateKey = identityPrivateKey
        self.identityCard = identityCard
        self.client = client
        self.longTermKeysStorage = longTermKeysStorage
        self.oneTimeKeysStorage = oneTimeKeysStorage
        self.sessionStorage = sessionStorage
        self.groupSessionStorage = groupSessionStorage
        self.keysRotator = keysRotator

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
    /// - Returns: GenericOperation<RotationLog>
    public func rotateKeys() -> GenericOperation<RotationLog> {
        Log.debug("Keys rotation queued")

        return self.keysRotator.rotateKeysOperation()
    }

    /// Stores session
    /// - Note: This method is used for storing new session as well as updating existing ones
    ///         after operations that change session's state (encrypt and decrypt),
    ///         therefore is session already exists in storage, it will be overwritten
    ///
    /// - Parameter session: [SecureSession](x-source-tag://SecureSession) to store
    /// - Throws: Rethrows from `SessionStorage`
    @objc open func storeSession(_ session: SecureSession) throws {
        Log.debug("Storing session with \(session.participantIdentity) name: \(session.name)")

        try self.sessionStorage.storeSession(session)
    }

    /// Stores group session
    /// - Note: This method is used for storing new session as well as updating existing ones
    ///         after operations that change session's state (encrypt, decrypt, setParticipants, updateParticipants),
    ///         therefore is session already exists in storage, it will be overwritten
    ///
    /// - Parameter session: [SecureGroupSession](x-source-tag://SecureGroupSession) to store
    /// - Throws: Rethrows from `GroupSessionStorage`
    @objc open func storeGroupSession(_ session: SecureGroupSession) throws {
        Log.debug("Storing group session with id \(session.identifier.hexEncodedString())")

        try self.groupSessionStorage.storeSession(session)
    }

    /// Checks for existing session with given participent in the storage
    ///
    /// - Parameters:
    ///   - participantIdentity: participant identity
    ///   - name: session name
    /// - Returns: [SecureSession](x-source-tag://SecureSession) if exists
    @objc open func existingSession(withParticipantIdentity participantIdentity: String,
                                    name: String? = nil) -> SecureSession? {
        if let session = self.sessionStorage.retrieveSession(participantIdentity: participantIdentity,
                                                             name: name ?? SecureChat.defaultSessionName) {
            Log.debug("Found existing session with \(participantIdentity)")

            return session
        }
        else {
            Log.debug("Existing session with \(participantIdentity) was not found")

            return nil
        }
    }

    /// Deletes session with given participant identity
    ///
    /// - Parameters:
    ///   - participantIdentity: participant identity
    ///   - name: Session name
    /// - Throws: Rethrows from SessionStorage
    @objc public func deleteSession(withParticipantIdentity participantIdentity: String, name: String? = nil) throws {
        Log.debug("Deleting session with \(participantIdentity)")

        try self.sessionStorage.deleteSession(participantIdentity: participantIdentity,
                                              name: name ?? SecureChat.defaultSessionName)
    }

    /// Deletes session with given participant identity
    ///
    /// - Parameter participantIdentity: participant identity
    /// - Throws: Rethrows from SessionStorage
    @objc public func deleteAllSessions(withParticipantIdentity participantIdentity: String) throws {
        Log.debug("Deleting session with \(participantIdentity)")

        try self.sessionStorage.deleteSession(participantIdentity: participantIdentity, name: nil)
    }

    /// Deletes group session with given identifier
    ///
    /// - Parameter sessionId: session identifier
    /// - Throws: Rethrows from SessionGroupStorage
    @objc public func deleteGroupSession(sessionId: Data) throws {
        Log.debug("Deleting group session with \(sessionId.hexEncodedString())")

        try self.groupSessionStorage.deleteSession(identifier: sessionId)
    }

    /// Starts new session with given participant using his identity card
    /// - Note: This operation doesn't store session to storage automatically. Use storeSession()
    ///
    /// - Parameters:
    ///   - receiverCard: receiver identity cards
    ///   - name: Session name
    /// - Returns: GenericOperation with [SecureSession](x-source-tag://SecureSession)
    /// - Throws:
    ///   - `SecureChatError.sessionAlreadyExists` if session already exists.
    ///     Try geting existing session or removing it
    ///   - `SecureChatError.wrongIdentityPublicKeyCrypto` PublicKey is not VirgilPublicKey
    ///   - `SecureChatError.identityKeyDoesntMatch` Identity key in the Card and on Ratchet Cloud doesn't match
    ///   - `SecureChatError.invalidLongTermKeySignature` Long-term key signature is invalid
    ///   - Rethrows from `SessionStorage`
    ///   - Rethrows from [RatchetClient](x-source-tag://RatchetClient)
    ///   - Rethrows form [SecureSession](x-source-tag://SecureSession)
    ///   - Rethrows form `AccessTokenProvider`
    open func startNewSessionAsSender(receiverCard: Card, name: String? = nil) -> GenericOperation<SecureSession> {
        Log.debug("Starting new session with \(receiverCard.identity) queued")

        return CallbackOperation { _, completion in
            do {
                Log.debug("Starting new session with \(receiverCard.identity)")

                guard self.existingSession(withParticipantIdentity: receiverCard.identity,
                                           name: name ?? SecureChat.defaultSessionName) == nil else {
                    throw SecureChatError.sessionAlreadyExists
                }

                let identityPublicKey = receiverCard.publicKey

                guard identityPublicKey.keyType == .ed25519 else {
                    throw SecureChatError.invalidKeyType
                }

                let publicKeySet = try self.client.getPublicKeySet(forRecipientIdentity: receiverCard.identity)

                let session = try self.startNewSessionAsSender(identity: receiverCard.identity,
                                                               identityPublicKey: identityPublicKey,
                                                               name: name,
                                                               identityPublicKeyData: publicKeySet.identityPublicKey,
                                                               longTermPublicKey: publicKeySet.longTermPublicKey,
                                                               oneTimePublicKey: publicKeySet.oneTimePublicKey)

                completion(session, nil)
            }
            catch {
                completion(nil, error)
            }
        }
    }

    /// Starts multiple new sessions with given participants using their identity cards
    /// - Note: This operation doesn't store sessions to storage automatically. Use storeSession()
    ///
    /// - Parameters:
    ///   - receiverCards: receivers identity cards
    ///   - name: Session name
    /// - Returns: GenericOperation with [SecureSession](x-source-tag://SecureSession) array
    /// - Throws:
    ///   - `SecureChatError.sessionAlreadyExists` if session already exists.
    ///     Try geting existing session or removing it
    ///   - `SecureChatError.wrongIdentityPublicKeyCrypto` PublicKey is not VirgilPublicKey
    ///   - `SecureChatError.identityKeyDoesntMatch` Identity key in the Card and on Ratchet Cloud doesn't match
    ///   - `SecureChatError.invalidLongTermKeySignature` Long-term key signature is invalid
    ///   - Rethrows from `SessionStorage`
    ///   - Rethrows from [RatchetClient](x-source-tag://RatchetClient)
    ///   - Rethrows form [SecureSession](x-source-tag://SecureSession)
    ///   - Rethrows form `AccessTokenProvider`
    open func startMutipleNewSessionsAsSender(receiverCards: [Card],
                                              name: String? = nil) -> GenericOperation<[SecureSession]> {
        Log.debug("Starting new session with \(receiverCards.map { $0.identity }) queued")

        return CallbackOperation { _, completion in
            do {
                Log.debug("Starting new session with \(receiverCards.map { $0.identity })")

                for card in receiverCards {
                    guard self.existingSession(withParticipantIdentity: card.identity,
                                               name: name ?? SecureChat.defaultSessionName) == nil else {
                        throw SecureChatError.sessionAlreadyExists
                    }

                    let identityPublicKey = card.publicKey

                    guard identityPublicKey.keyType == .ed25519 else {
                        throw SecureChatError.invalidKeyType
                    }
                }

                let publicKeysSets = try self.client
                    .getMultiplePublicKeysSets(forRecipientsIdentities: receiverCards.map { $0.identity })

                guard publicKeysSets.count == receiverCards.count else {
                    throw SecureChatError.publicKeysSetsMismatch
                }

                var sessions: [SecureSession] = []

                for card in receiverCards {
                    let set = publicKeysSets.first { $0.identity == card.identity }

                    guard let publicKeySet = set else {
                        throw SecureChatError.publicKeysSetsMismatch
                    }

                    let identityPublicKey = card.publicKey

                    let session = try self
                        .startNewSessionAsSender(identity: card.identity,
                                                 identityPublicKey: identityPublicKey,
                                                 name: name,
                                                 identityPublicKeyData: publicKeySet.identityPublicKey,
                                                 longTermPublicKey: publicKeySet.longTermPublicKey,
                                                 oneTimePublicKey: publicKeySet.oneTimePublicKey)

                    sessions.append(session)
                }

                completion(sessions, nil)
            }
            catch {
                completion(nil, error)
            }
        }
    }

    private func startNewSessionAsSender(identity: String,
                                         identityPublicKey: VirgilPublicKey,
                                         name: String? = nil,
                                         identityPublicKeyData: Data,
                                         longTermPublicKey: SignedPublicKey,
                                         oneTimePublicKey: Data?) throws -> SecureSession {
        guard try self.crypto.exportPublicKey(identityPublicKey) == identityPublicKeyData else {
            throw SecureChatError.identityKeyDoesntMatch
        }

        guard try self.crypto.verifySignature(longTermPublicKey.signature,
                                              of: longTermPublicKey.publicKey,
                                              with: identityPublicKey) else {
            throw SecureChatError.invalidLongTermKeySignature
        }

        if oneTimePublicKey == nil {
            Log.error("Creating weak session with \(identity)")
        }

        let privateKeyData = try self.crypto.exportPrivateKey(self.identityPrivateKey)

        let session = try SecureSession(crypto: self.crypto,
                                        participantIdentity: identity,
                                        name: name ?? SecureChat.defaultSessionName,
                                        senderIdentityPrivateKey: privateKeyData,
                                        receiverIdentityPublicKey: identityPublicKeyData,
                                        receiverLongTermPublicKey: longTermPublicKey.publicKey,
                                        receiverOneTimePublicKey: oneTimePublicKey)

        return session
    }

    private let queue = DispatchQueue(label: "VSRSecureChat", qos: .background)

    private func scheduleOneTimeKeyReplacement() {
        Log.debug("Adding one time key queued")

        // Replace one-time key after 1 seconds when chat is fully initialized
        self.queue.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1)) {
            Log.debug("Adding one time started")

            let oneTimePublicKey: Data

            do {
                try self.oneTimeKeysStorage.startInteraction()

                defer {
                    try? self.oneTimeKeysStorage.stopInteraction()
                }

                let keyPair = try self.crypto.generateKeyPair(ofType: .curve25519)

                let oneTimePrivateKey = try self.crypto.exportPrivateKey(keyPair.privateKey)
                oneTimePublicKey = try self.crypto.exportPublicKey(keyPair.publicKey)
                let keyId = try self.keyId.computePublicKeyId(publicKey: oneTimePublicKey)

                _ = try self.oneTimeKeysStorage.storeKey(oneTimePrivateKey, withId: keyId)

                Log.debug("Saved one-time key successfully")
            }
            catch {
                Log.error("Error saving one-time key")
                return
            }

            do {
                try self.client.uploadPublicKeys(identityCardId: nil,
                                                 longTermPublicKey: nil,
                                                 oneTimePublicKeys: [oneTimePublicKey])

                Log.debug("Added one-time key successfully")
            }
            catch {
                Log.error("Error adding one-time key")
            }
        }
    }

    /// Responds with new session with given participant using his initiation message
    /// - Note: This operation doesn't store session to storage automatically. Use storeSession()
    ///
    /// - Parameters:
    ///   - senderCard: Sender identity card
    ///   - name: session name (in case you want to have several sessions with same participant)
    ///   - ratchetMessage: Ratchet initiation message (should be prekey message)
    /// - Returns: [SecureSession](x-source-tag://SecureSession)
    /// - Throws:
    ///   - `SecureChatError.sessionAlreadyExists` if session already exists.
    ///     Try geting existing session or removing it
    ///   - `SecureChatError.wrongIdentityPublicKeyCrypto` PublicKey is not VirgilPublicKey
    ///   - Rethrows from `SessionStorage`
    ///   - Rethrows form [SecureSession](x-source-tag://SecureSession)
    ///   - Rethrows form `AccessTokenProvider`
    @objc public func startNewSessionAsReceiver(senderCard: Card,
                                                name: String? = nil,
                                                ratchetMessage: RatchetMessage) throws -> SecureSession {
        Log.debug("Responding to session with \(senderCard.identity) queued")

        guard self.existingSession(withParticipantIdentity: senderCard.identity, name: name) == nil else {
            throw SecureChatError.sessionAlreadyExists
        }

        let senderIdentityPublicKey = senderCard.publicKey

        guard senderIdentityPublicKey.keyType == .ed25519 else {
            throw SecureChatError.invalidKeyType
        }

        guard ratchetMessage.getType() == .prekey else {
            throw SecureChatError.invalidMessageType
        }

        let receiverLongTermPublicKey = ratchetMessage.getLongTermPublicKey()
        let longTermKeyId = try self.keyId.computePublicKeyId(publicKey: receiverLongTermPublicKey)
        let receiverLongTermPrivateKey = try self.longTermKeysStorage.retrieveKey(withId: longTermKeyId)

        let receiverOneTimePublicKey = ratchetMessage.getOneTimePublicKey()
        let receiverOneTimeKeyId: Data?

        if receiverOneTimePublicKey.isEmpty {
            receiverOneTimeKeyId = nil
        }
        else {
            receiverOneTimeKeyId = try self.keyId.computePublicKeyId(publicKey: receiverOneTimePublicKey)
        }

        let receiverOneTimePrivateKey: OneTimeKey?

        var interactionStarted = false

        if let receiverOneTimeKeyId = receiverOneTimeKeyId {
            try self.oneTimeKeysStorage.startInteraction()
            interactionStarted = true

            receiverOneTimePrivateKey = try self.oneTimeKeysStorage.retrieveKey(withId: receiverOneTimeKeyId)
        }
        else {
            receiverOneTimePrivateKey = nil
        }

        defer {
            if interactionStarted {
                try? self.oneTimeKeysStorage.stopInteraction()
            }
        }

        let session = try SecureSession(crypto: self.crypto,
                                        participantIdentity: senderCard.identity,
                                        name: name ?? SecureChat.defaultSessionName,
                                        receiverIdentityPrivateKey: self.identityPrivateKey,
                                        receiverLongTermPrivateKey: receiverLongTermPrivateKey,
                                        receiverOneTimePrivateKey: receiverOneTimePrivateKey,
                                        senderIdentityPublicKey: self.crypto.exportPublicKey(senderIdentityPublicKey),
                                        ratchetMessage: ratchetMessage)

        if let receiverOneTimeKeyId = receiverOneTimeKeyId {
            try self.oneTimeKeysStorage.deleteKey(withId: receiverOneTimeKeyId)

            self.scheduleOneTimeKeyReplacement()
        }

        return session
    }

    /// Creates RatchetGroupMessage that starts new group chat
    /// - Important: Session id is REQUIRED to be unique and tied to transport layer (channel id or similar)
    /// - Note: Other participants should receive this message using encrypted channel
    ///         ([SecureSession](x-source-tag://SecureSession))
    ///
    /// - Parameter sessionId: Session Id. Should be 32 byte.
    /// - Returns: RatchetGroupMessage that should be then passed to startGroupSession()
    /// - Throws:
    ///   - `SecureChatError.invalidSessionIdLen`
    ///   - Rethrows from `RatchetGroupTicket`
    @objc public func startNewGroupSession(sessionId: Data) throws -> RatchetGroupMessage {
        let ticket = RatchetGroupTicket()
        ticket.setRng(rng: self.crypto.rng)

        guard sessionId.count == RatchetCommon.sessionIdLen else {
            throw SecureChatError.invalidSessionIdLen
        }

        try ticket.setupTicketAsNew(sessionId: sessionId)

        return ticket.getTicketMessage()
    }

    /// Creates secure group session that was initiated by someone.
    /// - Important: RatchetGroupMessage should have .groupInfo type.
    ///              Such messages should be sent encrypted (using [SecureSession](x-source-tag://SecureSession))
    /// - Important: Session id is REQUIRED to be unique and tied to transport layer (channel id or similar)
    /// - Note: This operation doesn't store session to storage automatically. Use storeGroupSession()
    ///
    /// - Parameters:
    ///   - receiversCards: participant cards (excluding creating user itself)
    ///   - sessionId: Session Id. Should be 32 byte.
    ///   - ratchetMessage: ratchet group message with .groupInfo type
    /// - Returns: [SecureGroupSession](x-source-tag://SecureGroupSession)
    /// - Throws:
    ///   - `SecureChatError.invalidMessageType`
    ///   - `SecureChatError.invalidCardId`
    ///   - Rethrows from [SecureGroupSession](x-source-tag://SecureGroupSession)
    @objc public func startGroupSession(with receiversCards: [Card],
                                        sessionId: Data,
                                        using ratchetMessage: RatchetGroupMessage) throws -> SecureGroupSession {
        guard ratchetMessage.getType() == .groupInfo else {
            throw SecureChatError.invalidMessageType
        }

        guard ratchetMessage.getSessionId() == sessionId else {
            throw SecureChatError.sessionIdMismatch
        }

        let privateKeyData = try self.crypto.exportPrivateKey(self.identityPrivateKey)

        guard let myId = Data(hexEncodedString: self.identityCard.identifier) else {
            throw SecureChatError.invalidCardId
        }

        return try SecureGroupSession(crypto: self.crypto,
                                      privateKeyData: privateKeyData,
                                      myId: myId,
                                      ratchetGroupMessage: ratchetMessage,
                                      cards: receiversCards)
    }

    /// Returns existing group session
    ///
    /// - Parameter sessionId: session identifier
    /// - Returns: Stored session if found, nil otherwise
    @objc public func existingGroupSession(sessionId: Data) -> SecureGroupSession? {
        if let session = self.groupSessionStorage.retrieveSession(identifier: sessionId) {
            Log.debug("Found existing group session with identifier: \(sessionId)")

            return session
        }
        else {
            Log.debug("Existing session with identifier: \(sessionId) was not found")

            return nil
        }
    }

    /// Removes all data corresponding to this user: sessions and keys.
    ///
    /// - Returns: GenericOperation
    public func reset() -> GenericOperation<Void> {
        Log.debug("Reset queued")

        return CallbackOperation { _, completion in
            do {
                Log.debug("Started reset")

                Log.debug("Reseting cloud")
                try self.client.deleteKeysEntity()

                Log.debug("Reseting one-time keys")
                try self.oneTimeKeysStorage.reset()

                Log.debug("Reseting long-term keys")
                try self.longTermKeysStorage.reset()

                Log.debug("Reseting sessions")
                try self.sessionStorage.reset()

                Log.debug("Reseting success")

                completion(Void(), nil)
            }
            catch {
                completion(nil, error)
            }
        }
    }
}
