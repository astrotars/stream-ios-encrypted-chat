import UIKit
import Alamofire
import StreamChat
import StreamChatCore
import StreamChatClient

class UsersViewController: UITableViewController {
    let userDefaults = UserDefaults()
    var users = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUsers()
    }
    
    func loadUsers() {
        let authToken = userDefaults.string(forKey: "authToken")!
        let userId = userDefaults.string(forKey: "userId")!
        
        AF
            .request("https://57a385f3.ngrok.io/v1/users", method: .get, headers: ["Authorization" : "Bearer \(authToken)"])
            .responseJSON { response in
                let users = response.value as! [String]
                self.users = users.filter { $0 != userId }
                self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
        cell.textLabel!.text = users[indexPath.row]
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let userId = userDefaults.string(forKey: "userId")!
        let userToChatWith = users[tableView.indexPathForSelectedRow!.row]
        let channelId = [userId, userToChatWith].sorted().joined(separator: "-")
        let viewController = segue.destination as! EncryptedChatViewController
        
        let channelPresenter = ChannelPresenter(
            channel: Client.shared.channel(
                type: .messaging,
                id: channelId,
                members: [User(id: userId), User(id: userToChatWith)]
            )
        )
        
        viewController.presenter = channelPresenter
    }
}

