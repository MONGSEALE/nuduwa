//
//  ChatView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/11.
//

import SwiftUI

/*
struct ChatView: View {
    @State private var messageText = ""
        @StateObject private var viewModel = MeetingViewModel()
        @State private var userId = ""
    
    var meetingId: String
        
        var body: some View {
            VStack {
                List(viewModel.messages) { message in
                    Text(message.text)
                }
                HStack {
                    TextField("Enter message", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        viewModel.sendMessage(meetingId: meetingId, text: messageText, userId: userId)
                        messageText = ""
                    }) {
                        Text("Send")
                    }
                }.padding()
                TextField("Enter user ID", text: $userId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Button(action: {
                    viewModel.fetchData(meetingId: meetingId)
                }) {
                    Text("Load messages")
                }
            }
        }
    }
*/

struct ChatView: View {
    @EnvironmentObject var viewModel: MeetingViewModel
    @State private var messageText = ""
    @State private var isSignedIn = true
    @State private var userName = ""
    @State private var userId = ""
    @State private var isTyping = false
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    
    var meetingId: String
    
    var body: some View {
        VStack {
            if isSignedIn {
                List(viewModel.messages) { message in
                    ChatMessageRow(message: message, isFromCurrentUser: message.userId == self.userId)
                        .animation(.spring())
                }
                .animation(.spring())
                .onAppear {
                    self.viewModel.fetchData(meetingId: meetingId)
                }
                
                HStack {
                    TextField("Message", text: $messageText) { isEditing in
                        self.isTyping = isEditing
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
//                    
//                    Button(action: viewModel.sendMessage) {
//                        Text("Send")
//                    }
                    .disabled(messageText.isEmpty)
                    .padding(.trailing)
                }
                .padding(.bottom, self.isTyping ? 360 : 0)
                .animation(.spring())
            } else {
//                Button(action: signIn) {
//                    Text("Sign In Anonymously")
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(Color.blue)
//                        .cornerRadius(10)
//                }
            }
        }
        .navigationBarTitle("Chat")
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct ChatMessageRow: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    var body: some View {
        HStack {
            if !isFromCurrentUser {
                Text(message.userName)
                    .bold()
                    .padding(.trailing)
            }
            
            Text(message.text)
                .padding(10)
                .foregroundColor(.white)
                .background(isFromCurrentUser ? Color.blue : Color.gray)
                .cornerRadius(10)
                .padding(isFromCurrentUser ? .leading : .trailing, 20)
                .padding(isFromCurrentUser ? .trailing : .leading, 60)
            
            if isFromCurrentUser {
                Spacer()
            }
        }
    }
}
//
//struct ContentView: View {
//    @StateObject var viewModel = ChatViewModel()
//    var body: some View {
//        NavigationView {
//            ChatView()
//                .environmentObject(viewModel)
//                .navigationBarItems(trailing: Button(action: viewModel.signOut) {
//                    Text("Sign Out")
//                })
//        }
//    }
//}
