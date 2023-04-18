//
//  ChatView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/11.
//

import SwiftUI
import Firebase


struct ChatView: View {
    @StateObject var viewModel: ChatViewModel = .init()
//    @StateObject var viewModel: FirebaseViewModel = .init()
    
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    
    let hostId: String
    
    var meetingId: String
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView{
                    ForEach(viewModel.messages) { message in
                        ChatMessageRow(message: message, isFromCurrentUser: message.userId == Auth.auth().currentUser?.uid, isHost: message.userId == hostId)
                    }
                }
                .onChange(of: viewModel.lastMessageId) { id in
                    // When the lastMessageId changes, scroll to the bottom of the conversation
                    withAnimation {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
        }
        
        .onAppear {
            withAnimation(.spring()) {
                viewModel.messagesListner(meetingId: meetingId)
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
            
    }
}

struct ChatMessageRow: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    
    let isHost: Bool
    
    var body: some View {
        HStack {
            if !isFromCurrentUser {
                Text(message.userName)
            }else{
                Spacer()
            }
            Text(message.text)
                .padding(isHost ? 12 : 10)
                .foregroundColor(.white)
                .background(isFromCurrentUser ? Color.blue : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                //.padding(isFromCurrentUser ? .leading : .trailing, 20)
                //.padding(isFromCurrentUser ? .trailing : .leading, 60)
                .border(isHost ? Color.red : Color.clear, width: 5)
                .cornerRadius(10)
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
}

struct Chatting: View {
    @StateObject var viewModel: ChatViewModel = .init()
    @State private var messageText = ""
    //@State private var isTyping = false
    var meetingId: String
    
    var body: some View {
        HStack {
            TextField("Message", text: $messageText) { isEditing in
//                withAnimation {
//                    self.isTyping = isEditing
//                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            
            Button(action: {
                viewModel.sendMessage(meetingId: meetingId, text: messageText)
                closeKeyboard()
                messageText = ""
            }) {
                Text("보내기")
            }
            .disabled(messageText.isEmpty)
            .padding(.trailing)
        }
//        .padding(.bottom, self.isTyping ? 360 : 0)
//        .onChange(of: isTyping) { value in
//            withAnimation(.spring()) {
//                self.isTyping = value
//            }
//        }
    }
}
