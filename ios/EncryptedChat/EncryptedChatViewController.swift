import UIKit
import StreamChat
import StreamChatCore
import StreamChatClient

class EncryptedChatViewController: ChatViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter?.messagePreparationCallback = {
            var message = $0
            message.text = "helllooo"
            return message
        }
    }
    
    override func messageCell(at indexPath: IndexPath, message: Message, readUsers: [User]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "message")
            ?? UITableViewCell(style: .value2, reuseIdentifier: "message")
        
        cell.textLabel?.text = message.user.name
        cell.textLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        cell.detailTextLabel?.text = "hello helosdfasdfs"
        
        return cell
    }
}
