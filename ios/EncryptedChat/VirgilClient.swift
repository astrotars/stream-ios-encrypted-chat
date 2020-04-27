import VirgilE3Kit
import VirgilSDK

class VirgilClient {
    public static let shared = VirgilClient()
    
    private var eThree: EThree? = nil
    private var userCards: [String: Card] = [:]
    
    public static func configure(identity: String, token: String) {
        let tokenCallback: EThree.RenewJwtCallback = { completion in
            completion(token, nil)
        }
        let eThree = try! EThree(identity: identity, tokenCallback: tokenCallback)
        
        eThree.register { error in
            if let error = error {
                if error as? EThreeError == .userIsAlreadyRegistered {
                    print("Already registered")
                } else {
                    print("Failed registering: \(error.localizedDescription)")
                }
            }
        }
        
        shared.eThree = eThree
    }
    
    public func prepareUser(_ user: String) {
        eThree!.findUser(with: user) { [weak self] result, _ in
            self?.userCards[user] = result!
        }
    }
    
    public func encrypt(_ text: String, for user: String) -> String {
        return try! eThree!.authEncrypt(text: text, for: userCards[user]!)
    }
    
    public func decryptMine(_ text: String) -> String {
        return try! eThree!.authDecrypt(text: text)
    }
    
    public func decryptTheirs(_ text: String, from user: String) -> String {
        do {
            return try eThree!.authDecrypt(text: text, from: userCards[user]!)
        } catch {
            print("*********************")
            print(error.localizedDescription)
            print("*********************")
            return error.localizedDescription
        }
    }
}
