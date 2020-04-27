import UIKit

class LoginViewController: UIViewController {    
    @IBOutlet weak var usernameField: UITextField!
    
    @IBAction func login(_ sender: Any) {
        guard let userId = usernameField.text, !userId.isBlank else {
            usernameField.placeholder = " ⚠️ User id"
            return
        }
        
        Account.shared.login(userId) {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "UsersSegue", sender: self)
            }
        }
    }
}

