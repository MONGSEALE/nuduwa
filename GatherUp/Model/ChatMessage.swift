//
//  ChatMessage.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/11.
//

import SwiftUI
import Firebase

struct ChatMessage: Identifiable, Equatable {
    let id: String?
    let text: String
    let userId: String
    let userName: String
    let timestamp: Timestamp
}


