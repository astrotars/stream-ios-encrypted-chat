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

/// This class shows the result of rotateKeys operation
@objc(VSRRotationLog) public class RotationLog: NSObject, Encodable {
    /// Number of unused one-time keys
    @objc public var oneTimeKeysRelevant = 0

    /// NUmber of one-time keys that were generated and uploaded to the cloud during this operation
    @objc public var oneTimeKeysAdded = 0

    /// Number of one-time keys that were deleted during this rotation
    @objc public var oneTimeKeysDeleted = 0

    /// Number of one-time keys that were marked orphaned during this operation
    @objc public var oneTimeKeysMarkedOrphaned = 0

    /// Number of one-time keys that were marked orphaned
    @objc public var oneTimeKeysOrphaned = 0

    /// Number of relevant long-term keys
    @objc public var longTermKeysRelevant = 0

    /// Number of long-term keys that were generated and uploaded to the cloud during this operation
    @objc public var longTermKeysAdded = 0

    /// Number of long-term keys that were deleted during this rotation
    @objc public var longTermKeysDeleted = 0

    /// Number of long-term keys that were marked orphaned outdated this operation
    @objc public var longTermKeysMarkedOutdated = 0

    /// Number of long-term keys that were marked orphaned
    @objc public var longTermKeysOutdated = 0

    /// Pretty print JSON
    @objc override public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        guard let data = try? encoder.encode(self) else {
            return ""
        }

        guard let str = String(data: data, encoding: .utf8) else {
            return ""
        }

        return str
    }
}
