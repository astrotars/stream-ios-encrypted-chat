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

/// MARK: - Extension with objective-c methods
public extension KeysRotator {
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
    /// - Parameters:
    ///   - completion: completion handler
    ///   - rotationLog: represents the result of rotateKeys operation
    ///   - error: corresponding error
    @objc func rotateKeysOperation(completion: @escaping (_ rotationLog: RotationLog?, _ error: Error?) -> Void) {
        self.rotateKeysOperation().start(completion: completion)
    }
}
