//
//  EncryptedChatViewController.swift
//  EncryptedChat
//
//  Created by Jeff Taggart on 3/30/20.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatCore

class EncryptedChatViewController: ChatViewController {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Setup the general channel for the chat.
        let channel = Channel(type: .messaging, id: "general", name: "General")
        channelPresenter = ChannelPresenter(channel: channel)
    }
    /// Override the default implementation of UI messages
    /// with default UIKit table view cell.
    override func messageCell(at indexPath: IndexPath, message: Message, readUsers: [User]) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "message")
            ?? UITableViewCell(style: .value2, reuseIdentifier: "message")

          cell.textLabel?.text = message.user.name
          cell.textLabel?.font = .systemFont(ofSize: 12, weight: .bold)
          cell.detailTextLabel?.text = message.deleted == nil ? message.text : "This message was deleted"
          cell.detailTextLabel?.font = message.deleted == nil ? .systemFont(ofSize: 12) : .systemFont(ofSize: 12, weight: .light)
          cell.detailTextLabel?.numberOfLines = 0

        return cell
    }
}
