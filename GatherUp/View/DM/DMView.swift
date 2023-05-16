//
//  DMView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseFirestore
import Firebase
import FirebaseAuth

struct DMView: View {
    @StateObject private var viewModel = DMViewModel()
    
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    let receiverID: String
    @Binding var isDMViewPresented : Bool
    
    var body: some View {
        NavigationView{
            VStack {
                ScrollView{
                    ScrollViewReader { scrollViewProxy in
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.messages.indices, id: \.self) { index in
                                let message = viewModel.messages[index]
                                let previousMessage = index > 0 ? viewModel.messages[index - 1] : nil
                                
                                if isNewDay(previousMessage: previousMessage, currentMessage: message) {
                                    Text(formatDate(message.timestamp))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.top)
                                        .frame(maxWidth:.infinity)
                                }
                                
                                let isCurrentUser = message.senderID == viewModel.currentUID
                                
                                DMMessageRow(message: message, identifying: isCurrentUser, name: viewModel.user?.userName, image: viewModel.user?.userImage)
                            }
                        }
                        .onChange(of: viewModel.messages) { messages in
                            if let lastMessageIndex = messages.indices.last {
                                withAnimation {
                                    scrollViewProxy.scrollTo(lastMessageIndex, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                Spacer()
                HStack{
                    CustomTextFieldRow(placeholder: Text("메시지를 입력하세요"), text: $messageText)
                    Button{
                        viewModel.sendDM(message: messageText, receiverID: receiverID)
                        messageText = ""
                    }label: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color("lightblue"))
                            .cornerRadius(50)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical,10)
                .background(Color("gray"))
                .cornerRadius(50)
                .padding()
            }
            .navigationBarTitle("채팅방", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                         isDMViewPresented = false
                        print("뒤로")
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("뒤로")
                        }
                    }
                }
            }
            .onAppear {
                viewModel.startListeningDM(senderID: viewModel.currentUID!, receiverID: receiverID)
             //   viewModel.fetchUser(userUID: receiverID)
                viewModel.fetchChatRoomID(receiverID: receiverID) { chatRoomID in
                        viewModel.resetUnreadMessages(userID: Auth.auth().currentUser?.uid ?? "", chatRoomID: chatRoomID)
                    }
            }
            .onDisappear {
                print("바이")
                viewModel.removeListener()
            }
            
        }
    }
    func isNewDay(previousMessage: DM?, currentMessage: DM) -> Bool {
        guard let previousMessage = previousMessage else { return true }
        
        let calendar = Calendar.current
        let previousDate = previousMessage.timestamp.dateValue()
        let currentDate = currentMessage.timestamp.dateValue()
        
        return !calendar.isDate(previousDate, inSameDayAs: currentDate)
    }
    
    func formatDate(_ timestamp: Timestamp) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy" // Display date in "Month d, yyyy" format
        let date = timestamp.dateValue()
        return dateFormatter.string(from: date)
    }
}




struct DMMessageRow: View {
  
    @State var message : DM
    @State var identifying:Bool
    let name: String?
    let image: URL?
    

    var body: some View {
        HStack{
            if(identifying==false){
                WebImage(url:image ?? URL(string: ""))
                    .resizable()
                       .scaledToFill()
                       .frame(width: 40, height: 40)
                       .clipShape(Circle())
                VStack(alignment:.leading,spacing: 0, content: {
                    NickName(name: name ?? "")
                        .padding(.leading, 10)
                    ZStack {
                        Text(message.message)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .background(Color.blue.clipShape(ChatBubble()))
                    .padding(5)
                    
                    // Text(formatTimestamp(message.timestamp))
                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.leading,15)
                }
                )
                Spacer()
            }
            else{
                Spacer()
                VStack(alignment: .trailing){
                    ZStack{
                        Text(message.message)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .background(Color.red.clipShape(MyChatBubble()))
                    .padding(10)
                    
                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.trailing,15)
                }
            }
            
        }
    }
    // Function to format the timestamp
    func formatTimestamp(_ timestamp: Timestamp) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a" // Display time in "h:mm am/pm" format
        let date = timestamp.dateValue()
        return dateFormatter.string(from: date)
    }
    
    

}


struct DMChatBubble: Shape {
    func path(in rect: CGRect) -> Path{
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft,.topRight,.bottomRight],cornerRadii: CGSize(width: 15, height: 15))
        
        return Path(path.cgPath)
    }
}

struct DMMyChatBubble: Shape {
    func path(in rect: CGRect) -> Path{
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft,.topRight,.bottomLeft],cornerRadii: CGSize(width: 15, height: 15))
        
        return Path(path.cgPath)
    }
}

struct DMCustomTextFieldRow: View {
    var placeholder : Text
    @Binding var text : String
    var editingChanged: (Bool) -> () = {_ in}
    var commit: () -> () = {}
    
    var body: some View {
        ZStack(alignment: .leading){
            if(text.isEmpty){
                placeholder
                    .opacity(0.5)
            }
            TextField("",text:$text,onEditingChanged:editingChanged,onCommit:commit)
        }
    }
}


