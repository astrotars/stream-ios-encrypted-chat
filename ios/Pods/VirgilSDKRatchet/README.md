# Virgil Security Ratchet Objective-C/Swift SDK

[![Build Status](https://api.travis-ci.com/VirgilSecurity/virgil-ratchet-x.svg?branch=master)](https://travis-ci.com/VirgilSecurity/virgil-ratchet-x)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/VirgilSDKRatchet.svg)](https://cocoapods.org/pods/VirgilSDKRatchet)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/VirgilSDKRatchet.svg?style=flat)](https://cocoapods.org/pods/VirgilSDKRatchet)
[![GitHub license](https://img.shields.io/badge/license-BSD%203--Clause-blue.svg)](https://github.com/VirgilSecurity/virgil/blob/master/LICENSE)

[Introduction](#introduction) | [SDK Features](#sdk-features) | [Installation](#installation) | [Register Users](#register-users) | [Peer-to-peer Chat Example](#peer-to-peer-chat-example) | [Group Chat Example](#group-chat-example) | [Support](#support)

## Introduction

<a href="https://developer.virgilsecurity.com/docs"><img width="230px" src="https://cdn.virgilsecurity.com/assets/images/github/logos/virgil-logo-red.png" align="left" hspace="10" vspace="6"></a>
[Virgil Security](https://virgilsecurity.com) provides a set of services and open source libraries for adding security to any application. If you're developing a chat application, you'll understand the need for a  high level of data protection to ensure confidentiality and data integrity.

You may have heard of our [e3kit](https://github.com/VirgilSecurity/virgil-e3kit-x) which offers a high level of end-to-end encription, but if you need maximum protection with your application, Virgil Security presents the Double Ratchet SDK – an implementation of the [Double Ratchet Algorithm](https://signal.org/docs/specifications/doubleratchet/). With the powerful tools in this SDK, you can protect encrypted data, even if user messages or a private key has been stolen. The Double Ratchet SDK not only assigns a private encryption key with each chat session, but also allows the developer to limit the lifecycle of these keys. In the event an active key is stolen, it will expire according to the predetermined lifecycle you had set in your application.  

Ratchet SDK interacts with the [PFS service](https://developer.virgilsecurity.com/docs/api-reference/pfs-service/v5) to publish and manage one-time keys (OTK), long-term keys (LTK), and interacts with Virgil Cards service to retrieve the user identity cards the OTK and LTK are based on. The Ratchet SDK issues chat participants new keys for every chat session. As a result new session keys cannot be used to compromise past session keys.


# SDK Features
- communicate with Virgil PFS Service
- manage users' one-time keys (OTK) and long-term keys (LTK)
- enable group or peer-to-peer chat encryption
- uses the [Virgil crypto library](https://github.com/VirgilSecurity/virgil-crypto-c) and [Virgil Core SDK](https://github.com/VirgilSecurity/virgil-sdk-x)

## Installation

Virgil Ratchet SDK is provided as a set of frameworks distributed via Carthage and CocoaPods.

All frameworks are available for:
- iOS 9.0+
- macOS 10.11+
- tvOS 9.0+
- watchOS 2.0+

### COCOAPODS

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate Virgil Ratchet SDK into your Xcode project using CocoaPods, specify it in your *Podfile*:

```bash
target '<Your Target Name>' do
use_frameworks!

pod 'VirgilSDKRatchet', '~> 0.5.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides the binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate the Virgil Ratchet SDK into your Xcode project using Carthage, create an empty file with name *Cartfile* in your project's root folder and add following lines to your *Cartfile*

```
github "VirgilSecurity/virgil-ratchet-x" ~> 0.5.0
```

#### Linking against pre-built binaries

To link pre-built frameworks to your app, run the following command:

```bash
$ carthage update
```

This will build each dependency or download a pre-compiled framework from the github releases.

##### Building for iOS/tvOS/watchOS

On your application targets’ “General" settings tab, in the “Linked Frameworks and Libraries” section, add the following frameworks from the *Carthage/Build* folder inside your project's folder:
 - VirgilSDKRatchet
 - VirgilSDK
 - VirgilCrypto
 - VirgilCryptoFoundation
 - VirgilCryptoRatchet
 - VSCCommon
 - VSCFoundation
 - VSCRatchet

On your application targets’ “Build Phases" settings tab, click the “+” icon and choose “New Run Script Phase.” Create a Run Script to specify your shell (ex: */bin/sh*) then add the following contents:

```bash
/usr/local/bin/carthage copy-frameworks
```

Then add the paths to the frameworks you want to use under “Input Files”, e.g.:

```
$(SRCROOT)/Carthage/Build/iOS/VirgilSDKRatchet.framework
$(SRCROOT)/Carthage/Build/iOS/VirgilSDK.framework
$(SRCROOT)/Carthage/Build/iOS/VirgilCrypto.framework
$(SRCROOT)/Carthage/Build/iOS/VirgilCryptoFoundation.framework
$(SRCROOT)/Carthage/Build/iOS/VirgilCryptoRatchet.framework
$(SRCROOT)/Carthage/Build/iOS/VSCCommon.framework
$(SRCROOT)/Carthage/Build/iOS/VSCFoundation.framework
$(SRCROOT)/Carthage/Build/iOS/VSCRatchet.framework
```

##### Building for macOS

On your application target's “General” settings tab, in the “Embedded Binaries” section, drag and drop the following frameworks from the Carthage/Build folder:
 - VirgilSDKRatchet
 - VirgilSDK
 - VirgilCrypto
 - VirgilCryptoFoundation
 - VirgilCryptoRatchet
 - VSCCommon
 - VSCFoundation
 - VSCRatchet

Additionally, you'll need to copy the debug symbols for debugging and crash reporting on macOS.

On your application target’s “Build Phases” settings tab, click the “+” icon and choose “New Copy Files Phase”.
Click the “Destination” drop-down menu and select “Product Directory.” For each framework, drag and drop the corresponding dSYM file.

## Register Users

Make sure you have registered with the [Virgil Dashboard][_dashboard] and have created an E2EE V5 application.

Besides registering on your own server, users must also be registered on the Virgil Cloud. If they already are, you can skip this step and proceed to the next one.

Every Virgil user has a `Virgil Card` with an unlimited life-time on their device. The card contains a `Private Key`, `Public Key`, and the user's `identity`.

To register users on the Virgil Cloud (i.e. create and publish their `Identity Cards`), follow these steps:
- Set up your backend to generate a JWT to provide your service and users with access to the Virgil Cloud.
- Set up the client side for authenticating users on the Virgil Cloud.
- Set up the Cards Manager on your client side to generate and publish `Virgil Card` with Virgil Cards Service.

If you've already installed the Virgil Ratchet SDK or don't need to install the Virgil SDK or Virgil Crypto, you can use [this guide](https://developer.virgilsecurity.com/docs/how-to/public-key-management/v5/create-card) for the steps described above.


### Initialize SDK

To begin communicating with the PFS service and establish a secure session, each user must run the initialization. To do that, you need the Receiver's public key (identity card) from Virgil Cloud and the sender's private key from their local storage:

```swift
import VirgilSDKRatchet

let context = SecureChatContext(identityCard: card,
                                identityKeyPair: keyPair,
                                accessTokenProvider: provider)

let secureChat = try! SecureChat(context: context)

secureChat.rotateKeys().start { result in
    switch result {
    // Keys were rotated
    case .success(let rotationLog): break
    // Error occured
    case .failure(let error): break
    }
}
```

During the initialization process, using Identity Cards and the `rotateKeys` method we generate special keys that have their own life-time:

* **One-time Key (OTK)** - each time chat participants want to create a session, a single one-time key is obtained and discarded from the server.
* **Long-term Key (LTK)** - rotated periodically based on the developer's security considerations and is signed with the Identity Private Key.

## Peer-to-peer Chat Example
In this section you'll find out how to build a peer-to-peer chat using the Virgil Ratchet SDK.

### Send initial encrypted message
Let's assume Alice wants to start communicating with Bob and wants to send the first message:
- first, Alice has to create a new chat session by running the `startNewSessionAsSender` function and specify Bob's Identity Card
- then, Alice encrypts the initial message using the `encrypt` SDK function
- finally, The Ratchet SDK doesn't store and update sessions itself. Alice has to store the generated session locally with the `storeSession` SDK function.

```swift
import VirgilSDKRatchet

// prepare a message
let messageToEncrypt = "Hello, Bob!"

// start new secure session with Bob
let session = try! secureChat.startNewSessionAsSender(receiverCard: bobCard).startSync().get()

let ratchetMessage = try! session.encrypt(string: messageToEncrypt)

try! secureChat.storeSession(session)

let encryptedMessage = ratchetMessage.serialize()
```

**Important**: You need to store the session after operations that change the session's state (encrypt, decrypt), therefore if the session already exists in storage, it will be overwritten

### Decrypt the initial message

After Alice generates and stores the chat session, Bob also has to:
- start the chat session by running the `startNewSessionAsReceiver` function
- decrypt the encrypted message using the `decrypt` SDK function

```swift
import VirgilCryptoRatchet
import VirgilSDKRatchet

let ratchetMessage = try! RatchetMessage.deserialize(input: encryptedMessage)

let session = try! secureChat.startNewSessionAsReceiver(senderCard: aliceCard, ratchetMessage: ratchetMessage)

let decryptedMessage = try! session.decryptString(from: ratchetMessage)

try! secureChat.storeSession(session)
```

**Important**: You need to store sessions after operations that change the session's state (encrypt, decrypt). If the session already exists in storage, it will be overwritten

### Encrypt and decrypt messages

#### Encrypting messages
To encrypt future messages, use the `encrypt` function. This function allows you to encrypt data and strings.

> You also need to use message serialization to transfer encrypted messages between users. And do not forget to update sessions in storage as their state changes with every encryption operation!

- Use the following code-snippets to encrypt strings:

```swift
let session = secureChat.existingSession(withParticipantIdentity: bobCard.identity)!

let message = try! session.encrypt(string: "Hello, Bob!")

try! secureChat.storeSession(session)

let messageData = message.serialize()
// Send messageData to Bob
```

- Use the following code-snippets to encrypt data:

```Swift
let session = secureChat.existingSession(withParticipantIdentity: bobCard.identity)!

let message = try! session.encrypt(data: data)

try! secureChat.storeSession(session)

let messageData = message.serialize()
// Send messageData to Bob
```

#### Decrypting Messages
To decrypt messages, use the `decrypt` function. This function allows you to decrypt data and strings.

> You also need to use message serialization to transfer encrypted messages between users. And do not forget to update sessions in storage as their state changes with every decryption operation!

- Use the following code-snippets to decrypt strings:

```Swift
let session = secureChat.existingSession(withParticipantIdentity: aliceCard.identity)!

let message = try! RatchetMessage.deserialize(input: messageData)

let decryptedMessage = try! session.decryptString(from: message)

try! secureChat.storeSession(session)
```
- Use the following code-snippets to decrypt data:

```swift
let session = secureChat.existingSession(withParticipantIdentity: aliceCard.identity)

let message = try! RatchetMessage.deserialize(input: messageData)

let decryptedMessage = try! session.decryptData(from: message)

try! secureChat.storeSession(session)
```


## Group Chat Example
In this section, you'll find out how to build a group chat using the Virgil Ratchet SDK.

### Create Group Chat Ticket
Let's assume Alice wants to start a group chat with Bob and Carol. First, create a new group session ticket by running the `startNewGroupSession` method. This ticket holds a shared root key for future group encryption. Therefore, it should be encrypted and then transmitted to other group participants. Every group chat should have a unique 32-byte session identifier. We recommend tying this identifier to your unique transport channel id. If your channel id is not 32-bytes you can use SHA-256 to derive a session id from it.

```Swift
// Create transport channel according to your app logic and get session id from it
let sessionId = Data(hexEncodedString: "7f4f96cedbbd192ddeb08fbf3a0f5db0da14310c287f630a551364c54864c7fb")!

let ticket = try! secureChat.startNewGroupSession(sessionId: sessionId)
```

### Start Group Chat Session
Now, start the group session by running the `startGroupSession` function. This function requires specifying the group chat session ID, the receivers' Virgil Cards and tickets.

```Swift
let receiverCards = try! cardManager.searchCards(["Bob", "Carol"]).startSync().get()

let groupSession = try! secureChat.startGroupSession(with: receiverCards,
                                                     sessionId: sessionId,
                                                     using: ticket)
```

###  Store the Group Session
The Ratchet SDK doesn't store and update the group chat session itself. Use the `storeGroupSession` SDK function to store the chat sessions.

> Also, store existing session after operations that change the session's state (encrypt, decrypt, setParticipants, updateParticipants). If the session already exists in storage, it will be overwritten

```swift
try! secureChat.storeGroupSession(groupSession)
```

### Send the Group Ticket
Next, provide the group chat ticket to other members.

- First, serialize the ticket

```Swift
let ticketData = ticket.serialize()
```

- For security reasons, we can't send the unprotected ticket because it contains an unencrypted symmetric key. Therefore, we have to encrypt the serialized ticket for the receivers. The only secure way to do this is to use peer-to-peer Double Ratchet sessions with each participant to send the ticket.

```Swift
for card in receiverCards {
    guard let session = secureChat.existingSession(withParticipantIdentity: card.identity) else {
        // If you don't have session, see Peer-to-peer Chat Example on how to create it as Sender.
        return
    }

    let encryptedTicket = try! session.encrypt(data: ticketData).serialize()

    try! secureChat.storeGroupSession(groupSession)

    // Send ticket to receiver
}
```
- Next, use your application's business logic to share the encrypted ticket with the group chat participants.

### Join the Group Chat
Now, when we have the group chat created, other participants can join the chat using the group chat ticket.

- First, we have to decrypt the encrypted ticket

```Swift
guard let session = secureChat.existingSession(withParticipantIdentity: "Alice") else {
    // If you don't have a session, see the peer-to-peer chat example on how to create it as a receiver.
    return
}

let encryptedTicketMessage = try! RatchetMessage.deserialize(input: encryptedTicket)

let ticketData = session.decryptData(from: encryptedTicketMessage)
```

- Then, use the `deserialize` function to deserialize the session ticket.

```Swift
let ticket = try! RatchetGroupMessage.deserialize(input: ticketData)
```
- Join the group chat by running the `startGroupSession` function and store the session.

```Swift
let receiverCards = try! cardManager.searchCards(["Alice", "Bob"]).startSync().get()

let groupSession = try! secureChat.startGroupSession(with: receiverCards,
                                                     sessionId: sessionId,
                                                     using: ticket)

try! secureChat.storeGroupSession(groupSession)
```

### Encrypt and decrypt messages

#### Encrypting messages
In order to encrypt messages for the group chat, use the `encrypt` function. This function allows you to encrypt data and strings. You still need to use message serialization to transfer encrypted messages between users. And do not forget to update sessions in storage as their state is changed with every encryption operation!

- Use the following code-snippets to encrypt strings:
```swift
let message = try! groupSession.encrypt(string: "Hello, Alice and Bob!")

try! secureChat.storeGroupSession(groupSession)

let messageData = message.serialize()
// Send messageData to receivers
```

- Use the following code-snippets to encrypt data:
```Swift
let message = try! groupSession.encrypt(data: data)

try! secureChat.storeGroupSession(groupSession)

let messageData = message.serialize()
// Send messageData to receivers
```

#### Decrypting Messages
To decrypt messages, use the `decrypt` function. This function allows you to decrypt data and strings. Do not forget to update sessions in storage as their state changes with every encryption operation!

- Use the following code-snippets to decrypt strings:
```Swift
let message = RatchetGroupMessage.deserialize(input: messageData)

let carolCard = receiversCard.first { $0.identity == "Carol" }!

let decryptedMessage = try! groupSession.decryptString(from: message, senderCardId: carolCard.identifier)

try! secureChat.storeGroupSession(groupSession)
```
- Use the following code-snippets to decrypt data:
```swift
let message = RatchetGroupMessage.deserialize(input: messageData)

let carolCard = receiversCard.first { $0.identity == "Carol" }!

let data = try! groupSession.decryptData(from: message, senderCardId: carolCard.identifier)

try! secureChat.storeGroupSession(groupSession)
```


## License

This library is released under the [3-clause BSD License](LICENSE).

## Support
Our developer support team is here to help you. Find out more information at our [Help Center](https://help.virgilsecurity.com/).

You can find us on [Twitter](https://twitter.com/VirgilSecurity) or send us an email at support@VirgilSecurity.com.

Also, get extra help from our support team on [Slack](https://virgilsecurity.com/join-community).


[_sdk_x]: https://github.com/VirgilSecurity/virgil-sdk-x/tree/v5

[_dashboard]: https://dashboard.virgilsecurity.com/
[_virgil_crypto]: https://github.com/VirgilSecurity/virgil-crypto-c
[_reference_api]: https://developer.virgilsecurity.com/docs/api-reference
[_use_cases]: https://developer.virgilsecurity.com/docs/use-cases
[_use_case_pfs]:https://developer.virgilsecurity.com/docs/swift/use-cases/v5/perfect-forward-secrecy
