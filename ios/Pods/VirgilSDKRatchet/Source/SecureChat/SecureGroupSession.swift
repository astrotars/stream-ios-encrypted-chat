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
import VirgilCrypto
import VirgilCryptoRatchet

/// SecureGroupSession errors
///
/// - invalidUtf8String: invalid conversion to/from utf-8 string
/// - notConsequentTicket: consequent tickets should be passed to updateMembers
/// - invalidMessageType: invalid message type
/// - invalidCardId: invalid card id
/// - publicKeyIsNotVirgil: public key is not VirgilPublicKey
@objc(VSRSecureGroupSessionError) public enum SecureGroupSessionError: Int, LocalizedError {
    case invalidUtf8String = 1
    case notConsequentTicket = 2
    case invalidMessageType = 3
    case invalidCardId = 4
    case publicKeyIsNotVirgil = 5

    /// Human-readable localized description
    public var errorDescription: String {
        switch self {
        case .invalidUtf8String:
            return "invalid conversion to/from utf-8 string"
        case .notConsequentTicket:
            return "consequent tickets should be passed to updateMembers"
        case .invalidMessageType:
            return "invalid message type"
        case .invalidCardId:
            return "invalid card id"
        case .publicKeyIsNotVirgil:
            return "public key is not VirgilPublicKey"
        }
    }
}

/// SecureGroupSession
/// - Note: This class is thread-safe
/// - Tag: SecureGroupSession
@objc(VSRSecureGroupSession) public final class SecureGroupSession: NSObject {
    /// Crypto
    @objc public let crypto: VirgilCrypto

    /// Session id
    @objc public var identifier: Data {
        return self.ratchetGroupSession.getSessionId()
    }

    /// User identity card id
    @objc public var myIdentifier: String {
        return self.ratchetGroupSession.getMyId().hexEncodedString()
    }

    /// Number of participants
    @objc public var participantsCount: UInt32 {
        return self.ratchetGroupSession.getParticipantsCount()
    }

    /// Current epoch
    @objc public var currentEpoch: UInt32 {
        return self.ratchetGroupSession.getCurrentEpoch()
    }

    private let ratchetGroupSession: RatchetGroupSession
    private let queue = DispatchQueue(label: "SecureGroupSessionQueue")

    internal init(crypto: VirgilCrypto,
                  privateKeyData: Data,
                  myId: Data,
                  ratchetGroupMessage: RatchetGroupMessage,
                  cards: [Card]) throws {
        self.crypto = crypto

        let ratchetGroupSession = RatchetGroupSession()
        ratchetGroupSession.setRng(rng: crypto.rng)

        try ratchetGroupSession.setPrivateKey(myPrivateKey: privateKeyData)
        ratchetGroupSession.setMyId(myId: myId)

        let info = RatchetGroupParticipantsInfo(size: UInt32(cards.count))

        try cards.forEach { card in
            guard let participantId = Data(hexEncodedString: card.identifier) else {
                throw SecureGroupSessionError.invalidCardId
            }

            let publicKeyData = try crypto.exportPublicKey(card.publicKey)

            try info.addParticipant(id: participantId, pubKey: publicKeyData)
        }

        try ratchetGroupSession.setupSessionState(message: ratchetGroupMessage, participants: info)

        self.ratchetGroupSession = ratchetGroupSession

        super.init()
    }

    /// Encrypts string.
    /// - Note: This operation changes session state, so session should be updated in storage.
    ///
    /// - Parameter string: string to encrypt
    /// - Returns: RatchetMessage
    /// - Throws:
    ///   - `SecureGroupSessionError.invalidUtf8String` if given string is not correct utf-8 string
    ///   - Rethrows from crypto `RatchetGroupSession`
    @objc public func encrypt(string: String) throws -> RatchetGroupMessage {
        guard let data = string.data(using: .utf8) else {
            throw SecureGroupSessionError.invalidUtf8String
        }

        return try self.encrypt(data: data)
    }

    /// Encrypts data.
    /// - Note: This operation changes session state, so session should be updated in storage.
    ///
    /// - Parameter data: data to encrypt
    /// - Returns: RatchetMessage
    /// - Throws:
    ///   - Rethrows from crypto `RatchetGroupSession`
    @objc public func encrypt(data: Data) throws -> RatchetGroupMessage {
        return try self.queue.sync {
            let msg = try self.ratchetGroupSession.encrypt(plainText: data)

            return msg
        }
    }

    /// Decrypts data from RatchetMessage.
    /// - Note: This operation changes session state, so session should be updated in storage.
    ///
    /// - Parameters:
    ///   - message: RatchetGroupMessage
    ///   - senderCardId: Sender card id
    /// - Returns: Decrypted data
    /// - Throws:
    ///   - `SecureGroupSessionError.invalidMessageType` if message type is not .regular
    ///   - `SecureGroupSessionError.invalidCardId`
    ///   - Rethrows from crypto `RatchetGroupSession`
    @objc public func decryptData(from message: RatchetGroupMessage, senderCardId: String) throws -> Data {
        guard message.getType() == .regular else {
            throw SecureGroupSessionError.invalidMessageType
        }

        guard let senderId = Data(hexEncodedString: senderCardId) else {
            throw SecureGroupSessionError.invalidCardId
        }

        return try self.queue.sync {
            try self.ratchetGroupSession.decrypt(message: message, senderId: senderId)
        }
    }

    /// Decrypts utf-8 string from RatchetMessage.
    /// - Note: This operation changes session state, so session should be updated in storage.
    ///
    /// - Parameters:
    ///   - message: RatchetGroupMessage
    ///   - senderCardId: Sender card id
    /// - Returns: Decrypted utf-8 string
    /// - Throws:
    ///   - `SecureGroupSessionError.invalidUtf8String` if decrypted data is not correct utf-8 string
    ///   - `SecureGroupSessionError.invalidMessageType` if message type is not .regular
    ///   - `SecureGroupSessionError.invalidCardId`
    ///   - Rethrows from crypto `RatchetGroupSession`
    @objc public func decryptString(from message: RatchetGroupMessage, senderCardId: String) throws -> String {
        let data = try self.decryptData(from: message, senderCardId: senderCardId)

        guard let string = String(data: data, encoding: .utf8) else {
            throw SecureGroupSessionError.invalidUtf8String
        }

        return string
    }

    /// Creates ticket for adding/removing participants, or just to rotate secret
    ///
    /// - Returns: `RatchetGroupMessage`
    /// - Throws: Rethrows from crypto `RatchetGroupSession`
    @objc public func createChangeParticipantsTicket() throws -> RatchetGroupMessage {
        return try self.ratchetGroupSession.createGroupTicket().getTicketMessage()
    }

    /// Sets participants
    ///
    /// - Parameters:
    ///   - ticket: ticket
    ///   - cards: participants cards
    /// - Throws:
    ///   - `SecureGroupSessionError.invalidMessageType`
    ///   - `SecureGroupSessionError.invalidCardId`
    ///   - `SecureGroupSessionError.publicKeyIsNotVirgil`
    ///   - Rethrows from `RatchetGroupSession`
    @objc public func setParticipants(ticket: RatchetGroupMessage,
                                      cards: [Card]) throws {
        guard ticket.getType() == .groupInfo else {
            throw SecureGroupSessionError.invalidMessageType
        }

        let info = RatchetGroupParticipantsInfo(size: UInt32(cards.count))

        try cards.forEach { card in
            guard let participantId = Data(hexEncodedString: card.identifier) else {
                throw SecureGroupSessionError.invalidCardId
            }

            let publicKeyData = try self.crypto.exportPublicKey(card.publicKey)

            try info.addParticipant(id: participantId, pubKey: publicKeyData)
        }

        try self.ratchetGroupSession.setupSessionState(message: ticket,
                                                       participants: info)
    }

    /// Updates incrementaly participants
    /// - Important: As this update is incremental, tickets should be applied strictly consequently
    /// - Note: This operation changes session state, so session should be updated in storage.
    ///         Otherwise, use setParticipants()
    ///
    /// - Parameters:
    ///   - ticket: ticket
    ///   - addCards: participants to add
    ///   - removeCardIds: participants to remove
    /// - Throws:
    ///   - `SecureGroupSessionError.notConsequentTicket`
    ///   - `SecureGroupSessionError.invalidMessageType`
    ///   - `SecureGroupSessionError.invalidCardId`
    ///   - `SecureGroupSessionError.publicKeyIsNotVirgil`
    ///   - Rethrows from crypto `RatchetGroupSession`
    @objc public func updateParticipants(ticket: RatchetGroupMessage,
                                         addCards: [Card],
                                         removeCardIds: [String]) throws {
        guard ticket.getType() == .groupInfo else {
            throw SecureGroupSessionError.invalidMessageType
        }

        guard ticket.getEpoch() == self.ratchetGroupSession.getCurrentEpoch() + 1 else {
            throw SecureGroupSessionError.notConsequentTicket
        }

        let addInfo = RatchetGroupParticipantsInfo(size: UInt32(addCards.count))
        let removeInfo = RatchetGroupParticipantsIds(size: UInt32(removeCardIds.count))

        try addCards.forEach { card in
            guard let participantId = Data(hexEncodedString: card.identifier) else {
                throw SecureGroupSessionError.invalidCardId
            }

            let publicKeyData = try self.crypto.exportPublicKey(card.publicKey)

            try addInfo.addParticipant(id: participantId, pubKey: publicKeyData)
        }

        try removeCardIds.forEach { id in
            guard let idData = Data(hexEncodedString: id) else {
                throw SecureGroupSessionError.invalidCardId
            }

            removeInfo.addId(id: idData)
        }

        try self.ratchetGroupSession.updateSessionState(message: ticket,
                                                        addParticipants: addInfo,
                                                        removeParticipants: removeInfo)
    }

    /// Init session from serialized representation
    ///
    /// - Parameters:
    ///   - data: Serialized session
    ///   - privateKeyData: exported private key
    ///   - crypto: VirgilCrypto
    /// - Throws: Rethrows from crypto `RatchetGroupSession`
    @objc public init(data: Data, privateKeyData: Data, crypto: VirgilCrypto) throws {
        self.crypto = crypto
        let ratchetGroupSession = try RatchetGroupSession.deserialize(input: data)
        ratchetGroupSession.setRng(rng: crypto.rng)
        try ratchetGroupSession.setPrivateKey(myPrivateKey: privateKeyData)

        self.ratchetGroupSession = ratchetGroupSession

        super.init()
    }

    /// Serialize session
    ///
    /// - Returns: Serialized data
    @objc public func serialize() -> Data {
        return self.ratchetGroupSession.serialize()
    }
}
