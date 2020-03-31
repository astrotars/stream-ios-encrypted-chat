import UIKit
import StreamChat
import StreamChatCore

class EncryptedChatViewController: ChatViewController {
    override func messageCell(at indexPath: IndexPath, message: Message, readUsers: [User]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "message")
            ?? UITableViewCell(style: .value2, reuseIdentifier: "message")
        
        cell.textLabel?.text = message.user.name
        cell.textLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        cell.detailTextLabel?.text = "hello helosdfasdfs"
        
        return cell
    }
}
