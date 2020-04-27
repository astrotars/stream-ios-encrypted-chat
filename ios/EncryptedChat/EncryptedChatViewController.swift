import UIKit
import StreamChat
import StreamChatCore
import StreamChatClient

class EncryptedChatViewController: ChatViewController {
    var user: String?
    var otherUser: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let presenter = presenter else {
            return
        }
        
        VirgilClient.shared.prepareUser(otherUser!)
        
        presenter.messagePreparationCallback = {
            var message = $0
            message.text = VirgilClient.shared.encrypt(message.text, for: self.otherUser!)
            return message
        }
    }
    
    override func messageCell(at indexPath: IndexPath, message: Message, readUsers: [User]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "message")
            ?? UITableViewCell(style: .value2, reuseIdentifier: "message")
        
        cell.textLabel?.text = message.user.name
        cell.textLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        
        cell.detailTextLabel?.text = message.user.id == user ?
            VirgilClient.shared.decryptMine(message.text) :
            VirgilClient.shared.decryptTheirs(message.text, from: otherUser!)
        
        return cell
    }
}
