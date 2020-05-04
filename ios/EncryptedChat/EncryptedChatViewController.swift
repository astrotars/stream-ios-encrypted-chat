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
        var modifyMessage = message
        
        modifyMessage.text = message.user.id == user ?
            VirgilClient.shared.decryptMine(message.text) :
            VirgilClient.shared.decryptTheirs(message.text, from: otherUser!)

        return super.messageCell(at: indexPath, message: modifyMessage, readUsers: readUsers)
    }
}
