import UIKit
import Alamofire
import StreamChat
import StreamChatCore
import StreamChatClient

class UsersViewController: UITableViewController {
    var users = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUsers()
    }
    
    func loadUsers() {
        Account.shared.users { users in
            self.users = users
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
        let userId = Account.shared.userId!
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
        
        viewController.user = userId
        viewController.otherUser = userToChatWith
        viewController.presenter = channelPresenter
    }
}

