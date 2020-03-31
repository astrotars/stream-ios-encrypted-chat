import VirgilE3Kit

class VirgilClient {
    public static let shared = VirgilClient()
    
    private var eThree: EThree? = nil
    
    public static func configure(identity: String, token: String) {
        let tokenCallback: EThree.RenewJwtCallback = { completion in
            completion(token, nil)
        }
        let eThree = try! EThree(identity: identity, tokenCallback: tokenCallback)
        
        if (try? eThree.hasLocalPrivateKey()) == true {
            try? eThree.cleanUp()
        }
        
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
}
