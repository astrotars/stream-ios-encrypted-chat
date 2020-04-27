import Alamofire
import StreamChatClient
import VirgilE3Kit

class Account {
    public static let shared = Account()

    let apiRoot = "https://57a385f3.ngrok.io"
    var authToken: String? = nil
    var userId: String? = nil

    public func login(_ userId: String, completion: @escaping () -> Void) {
        AF
            .request("\(apiRoot)/v1/authenticate",
                     method: .post,
                     parameters: ["user" : userId],
                     encoder: JSONParameterEncoder.default)
            .responseJSON { response in
                let body = response.value as! NSDictionary
                let authToken = body["authToken"]! as! String

                self.authToken = authToken
                self.userId = userId
                
                self.setupStream(completion)
        }
    }
    
    public func users(completion: @escaping ([String]) -> Void) {
        AF
            .request("\(apiRoot)/v1/users", method: .get, headers: ["Authorization" : "Bearer \(authToken!)"])
            .responseJSON { response in
                let users = response.value as! [String]
                completion(users.filter { $0 != self.userId! })
        }
    }
    
    
    private func setupStream(_ completion: @escaping () -> Void)  {
        AF
            .request("\(apiRoot)/v1/stream-credentials",
                     method: .post,
                     headers: ["Authorization" : "Bearer \(authToken!)"])
            .responseJSON { response in
                let body = response.value as! NSDictionary
                let token = body["token"]! as! String
                let apiKey = body["apiKey"]! as! String
                
                Client.config = .init(apiKey: apiKey, logOptions: .info)
                Client.shared.set(
                    user: User(id: self.userId!),
                    token: token
                )
                
                self.setupVirgil(completion)
        }
    }
    
    private func setupVirgil(_ completion: @escaping () -> Void) {
        AF
            .request("\(apiRoot)/v1/virgil-credentials",
                     method: .post,
                     headers: ["Authorization" : "Bearer \(authToken!)"])
            .responseJSON { response in
                let body = response.value as! NSDictionary
                let token = body["token"]! as! String
          
                VirgilClient.configure(identity: self.userId!, token: token)
                
                completion()
        }
    }
}
