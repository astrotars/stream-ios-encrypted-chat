import UIKit
import StreamChatClient
import Alamofire
import VirgilE3Kit

class LoginViewController: UIViewController {
    let userDefaults = UserDefaults()
    let apiRoot = "https://57a385f3.ngrok.io"
    
    @IBOutlet weak var usernameField: UITextField!
    
    @IBAction func login(_ sender: Any) {
        guard let userId = usernameField.text, !userId.isBlank else {
            usernameField.placeholder = " ⚠️ User id"
            return
        }
        
        AF
            .request("\(apiRoot)/v1/authenticate",
                     method: .post,
                     parameters: ["user" : userId],
                     encoder: JSONParameterEncoder.default)
            .responseJSON { response in
                let body = response.value as! NSDictionary
                let authToken = body["authToken"]! as! String

                self.userDefaults.set(authToken, forKey: "authToken")
                self.userDefaults.set(userId, forKey: "userId")
                self.userDefaults.synchronize()
                
                self.setupStream(userId: userId, authToken: authToken)
        }
        
    }
    
    func setupStream(userId: String, authToken: String)  {
        AF
            .request("\(apiRoot)/v1/stream-credentials",
                     method: .post,
                     headers: ["Authorization" : "Bearer \(authToken)"])
            .responseJSON { response in
                let body = response.value as! NSDictionary
                let token = body["token"]! as! String
                let apiKey = body["apiKey"]! as! String
                
                Client.config = .init(apiKey: apiKey, logOptions: .info)
                Client.shared.set(
                    user: User(id: userId),
                    token: token
                )
                
                self.setupVirgil(authToken)
        }
    }
    
    func setupVirgil(_ authToken: String) {
        AF
            .request("\(apiRoot)/v1/virgil-credentials",
                     method: .post,
                     headers: ["Authorization" : "Bearer \(authToken)"])
            .responseJSON { response in
                let userId = self.userDefaults.string(forKey: "userId")!
                let body = response.value as! NSDictionary
                let token = body["token"]! as! String
          
                VirgilClient.configure(identity: userId, token: token)
                
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "UsersSegue", sender: self)
                }
        }
    }
}

