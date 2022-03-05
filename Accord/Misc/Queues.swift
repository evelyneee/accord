//
//  Queues.swift
//  Accord
//
//  Created by evelyn on 2021-12-22.
//

import Foundation

// For all operations related to markdown/text
// Used by ChatControlsView for emote autocomplete and MessageCellView for markdown in the text view
let textQueue = DispatchQueue(label: "AccordTextQueue", attributes: .concurrent)

// For all image loading
let imageQueue = DispatchQueue(label: "AccordImageQueue", attributes: .concurrent)

// The thread the websocket operations run on
let wssThread = DispatchQueue(label: "AccordWSOperationsQueue", attributes: .concurrent)

// The thread websocket events are decoded
let webSocketQueue = DispatchQueue(label: "AccordWSDecodingQueue", attributes: .concurrent)

// queue where the websocket lives
let concurrentQueue = DispatchQueue(label: "AccordMainWSQueue", attributes: .concurrent)

// Message fetching queue - Used by PinsView, ChannelView's view model for fetching messages and loading the rest of the things
let messageFetchQueue = DispatchQueue(label: "AccordMessageFetchQueue", attributes: .concurrent)

// Message sending queue - Used by ChatControlsView
let messageSendQueue = DispatchQueue(label: "AccordMessageSendQueue", attributes: .concurrent)

// Gif loading queue
let gifQueue = DispatchQueue(label: "AccordGifQueue")
