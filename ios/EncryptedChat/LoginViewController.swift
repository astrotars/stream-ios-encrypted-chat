import UIKit
import StreamChat
import StreamChatCore
import Alamofire

class LoginViewController: UIViewController {
    let userDefaults = UserDefaults()
    
    @IBOutlet weak var usernameField: UITextField!
    
    @IBAction func login(_ sender: Any) {
        guard let userId = usernameField.text, !userId.isBlank else {
            usernameField.placeholder = " ⚠️ User id"
            return
        }
        
        
        AF
            .request("https://ea3dfd9a.ngrok.io/v1/authenticate",
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
            .request("https://ea3dfd9a.ngrok.io/v1/stream-credentials",
                     method: .post,
                     headers: ["Authorization" : "Bearer \(authToken)"])
            .responseJSON { response in
                let body = response.value as! NSDictionary
                let token = body["token"]! as! String
                
                Client.config = .init(apiKey: "whe3wer2pf4r", logOptions: .info)
                Client.shared.set(
                    user: User(id: userId, name: userId),
                    token: token
                )
                
                self.setupVirgil(authToken)
        }
    }
    
    func setupVirgil(_ authToken: String) {
        AF
            .request("https://ea3dfd9a.ngrok.io/v1/virgil-credentials",
                     method: .post,
                     headers: ["Authorization" : "Bearer \(authToken)"])
            .responseJSON { response in
                let body = response.value as! NSDictionary
                let token = body["token"]! as! String
                
                self.userDefaults.set(token, forKey: "virgilToken")
                self.userDefaults.synchronize()
                
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "UsersSegue", sender: self)
                }
        }
    }
}

