//
//  ChatView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/03.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI

struct ChatView: View {

    let meetingID : String
    let meetingTitle: String
    let hostUID: String

    @State var message = ""
    @StateObject var chatViewModel = ChatViewModel()
   
    @Binding var members: [String: Member]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showMemberList = false
    @State private var xOffset: CGFloat = UIScreen.main.bounds.width
    
    @Binding var showDMView: Bool
    @Binding var receiverID: String?
    
  
    
    var body: some View {
        ZStack{
            VStack{
                if(showMemberList==true){
                    Spacer()
                        .frame(height: 38)
                }
                ScrollView{
                    ScrollViewReader { scrollViewProxy in
                        VStack {
                            ForEach(chatViewModel.messages.indices, id: \.self) { index in
                                let currentMessage = chatViewModel.messages[index]
                                let previousMessage = index > 0 ? chatViewModel.messages[index - 1] : nil
                                
                                if isNewDay(previousMessage: previousMessage, currentMessage: currentMessage) {
                                    Text(formatDate(currentMessage.timestamp))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .id("system-\(index)")
                                }
                                if currentMessage.isSystemMessage {
                                    Text(currentMessage.text)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .id("system-\(index)")
                                }
                                else{
                                    MessageRow(message: currentMessage, member: members[currentMessage.senderUID] ?? chatViewModel.nonMembers[currentMessage.senderUID] ??
                                               Member(memberUID: ""), identifying: currentMessage.senderUID == chatViewModel.currentUID)
                                }
                            }
                        }
                        .padding(10)
                        .onChange(of: chatViewModel.messages) { messages in
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
                    CustomTextFieldRow(placeholder: Text("메시지를 입력하세요"), text: $message)
                    Button{
                        chatViewModel.sendMessage(meetingID: meetingID , text: message)
                        message = ""
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
            .navigationBarTitle("\(meetingTitle) (\(members.values.count))", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("뒤로")
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        withAnimation(.easeInOut) {
                            self.showMemberList = true
                        }
                    }) {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            MemberList(meetingID: meetingID, members: Array(members.values), hostUID: hostUID ,userUID: chatViewModel.currentUID!, receiverID: $receiverID, showDMView: $showDMView)
                           .slideOverView(isPresented: $showMemberList)
                           .onDisappear{
                               showMemberList = false
                           }
        }
        .navigationBarHidden(showMemberList)
        .onAppear{
            chatViewModel.messagesListener(meetingID: meetingID)     // 채팅들이 화면에 보이게함
        }
    }
    func formatDate(_ timestamp: Timestamp) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy" // Display date in "Month d, yyyy" format
        let date = timestamp.dateValue()
        return dateFormatter.string(from: date)
    }
    
    func isNewDay(previousMessage: Message?, currentMessage: Message) -> Bool {
        guard let previousMessage = previousMessage else { return true }
        
        let calendar = Calendar.current
        let previousDate = previousMessage.timestamp.dateValue()
        let currentDate = currentMessage.timestamp.dateValue()
        
        return !calendar.isDate(previousDate, inSameDayAs: currentDate)
    }
}

struct MemberList: View {
    let meetingID: String
    let members: [Member]
    let hostUID: String
    let userUID: String
    
    @Binding var receiverID: String?
    @Binding var showDMView: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text("대화 상대")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding()

            ScrollView {
                LazyVStack {
                    ForEach(members) { member in
                        MemberItemView(meetingID: meetingID, member: member, hostUID: hostUID, userUID: userUID, receiverID: $receiverID, showDMView: $showDMView)
                    }
                }
            }
            
        }
        .background(Color(.systemGroupedBackground))
        .cornerRadius(20)
        .padding(.horizontal, 10)
    }
}
struct MemberItemView: View {
    let meetingID: String
    let member: Member
    let hostUID: String
    let userUID: String
    @State var isShowMember: Bool = false
    @StateObject var viewModel: MeetingViewModel = .init()
    
    @Binding var receiverID: String?
    @Binding var showDMView: Bool
    
    
    var body: some View {
            HStack {
                if hostUID == userUID && member.memberUID != userUID {
                    Menu {
                        Button("프로필보기", action: {isShowMember = true})
                        Button("추방하기", role: .destructive, action: {
                            viewModel.leaveMeeting(meetingID: meetingID, memberUID: member.memberUID)
                        })
                    } label: {
                        MemberChatImage(image: member.memberImage!)
                    }
                } else {
                    Button{
                        isShowMember = true
                    } label: {
                        MemberChatImage(image: member.memberImage!)
                    }
                }
                
                if member.memberUID == userUID {
                    Text("나 - \(member.memberName ?? "")")
                        .font(.body)
                } else {
                    Text(member.memberName ?? "")
                        .font(.body)
                }
                Spacer()
            }
            .sheet(isPresented: $isShowMember){
                MemberProfileView(member: member, isCurrent: member.memberUID == viewModel.currentUID, receiverID: $receiverID, showDMView: $showDMView)
            }
            .padding(.horizontal)
    }
}
struct MemberChatImage: View {
    let image: URL
    
    var body: some View {
        WebImage(url: image).placeholder{ProgressView()}
            .resizable()
            .scaledToFill()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
    }
}

struct NickName: View {
    var name : String
    
    var body: some View{
        Text(String(name))
    }
}

struct MessageRow: View {
  
    let message: Message
    let member: Member
    let identifying: Bool

    var body: some View {
        HStack{
            if(identifying==false){
                WebImage(url: member.memberImage).placeholder{ProgressView()}
                    .resizable()
                   .scaledToFill()
                   .frame(width: 40, height: 40)
                   .clipShape(Circle())
                VStack(alignment:.leading,spacing: 0, content: {
                    NickName(name: member.memberName ?? "")
                        .padding(.leading, 10)
                    ZStack {
                        Text(message.text)
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
                        Text(message.text)
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

struct ChatBubble: Shape {
    func path(in rect: CGRect) -> Path{
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft,.topRight,.bottomRight],cornerRadii: CGSize(width: 15, height: 15))
        
        return Path(path.cgPath)
    }
}

struct MyChatBubble: Shape {
    func path(in rect: CGRect) -> Path{
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft,.topRight,.bottomLeft],cornerRadii: CGSize(width: 15, height: 15))
        
        return Path(path.cgPath)
    }
}

struct CustomTextFieldRow: View {
    let placeholder : Text
    @Binding var text : String
    // var editingChanged: (Bool) -> () = {_ in}
    // var commit: () -> () = {}
    
    var body: some View {
        ZStack(alignment: .leading){
            if(text.isEmpty){
                placeholder
                    .opacity(0.5)
            }
            TextField("",text:$text) //,onEditingChanged:editingChanged,onCommit:commit)
        }
    }
}
