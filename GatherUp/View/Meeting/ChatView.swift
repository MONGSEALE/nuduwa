//
//  ChatView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/03.
//

import SwiftUI
import Firebase
import SDWebImageSwiftUI
import UIKit
import PhotosUI



struct ChatView: View {

    let meetingID : String
    let meetingTitle: String
    let hostUID: String
    
    @State private var isExpanded = false
    @State var message = ""
    @StateObject var chatViewModel = ChatViewModel()
   
    @Binding var members: [String: Member]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showMemberList = false
    @State private var xOffset: CGFloat = UIScreen.main.bounds.width
    @State var isPickerShowing = false
    @State private var isPresented : Bool = false
    @State private var capturedImage: UIImage? = nil

  //  @StateObject var photosModel:PhotoPickerModel = .init()
  //   @StateObject var photosModel: PhotoPickerModel
    @ObservedObject var photosModel=PhotoPickerModel()

    
    
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
                               
                                
                                let isContinuousFromLastMessage =
                                  (currentMessage.senderUID == previousMessage?.senderUID)
                                  && !(previousMessage?.isSystemMessage ?? false)
                                  && !isNewDay(previousMessage: previousMessage, currentMessage: currentMessage)

                                
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
                                               Member(memberUID: ""), identifying: currentMessage.senderUID == chatViewModel.currentUID,isContinuousFromLastMessage:isContinuousFromLastMessage)
                                    .id("message-\(index)")
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
                    Button{
                        isExpanded.toggle()
                        if !isExpanded {
                            UIApplication.shared.endEditing()
                        }
                    } label:{
                        Image(systemName: "plus.circle")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.gray)
                    }
                        CustomTextFieldRow(placeholder: Text("메시지를 입력하세요"), text: $message)
                        .background(Color("lightgray"))
                        .cornerRadius(50)
                    Button{
                        chatViewModel.sendMessage(meetingID: meetingID , text: message)
                        message = ""
                    }label: {
                        Image(systemName: "paperplane.fill")
                            
                            .foregroundColor(.white)
                            .padding(10)
                            .background(message.isEmpty ? Color.gray : Color("lightblue"))
                            .cornerRadius(50)
                    }
                    .disabled(message.isEmpty)
                }
                if isExpanded {
                HStack {
                    PhotosPicker(selection:$photosModel.imageSelections, matching: .images){
                        Image(systemName: "photo")
                    }
                    Button(action: {
                        self.isPresented = true
                    }) {
                        Image(systemName: "camera")
                    }
                    .fullScreenCover(isPresented: $isPresented) {
                        CameraView(isPresented: self.$isPresented, image: self.$capturedImage)
                    }

                                   Button(action: {
                                       // 장소 기능 구현
                                   }) {
                                       Image(systemName: "location")
                                   }
                }
            }
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
            MemberList(meetingID: meetingID, members: Array(members.values), hostUID: hostUID ,userUID: chatViewModel.currentUID ?? "")
                           .slideOverView(isPresented: $showMemberList)
                           .onDisappear{
                               showMemberList = false
                           }
        }
        .navigationBarHidden(showMemberList)
        .onAppear{
            chatViewModel.messagesListener(meetingID: meetingID)
            photosModel.meetingID = meetingID
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
    var members: [Member]
    let hostUID: String
    let userUID: String
    
    var sortedMembers: [Member] {
        members.sorted { (member1, member2) -> Bool in
            if member1.memberUID == userUID {
                return true
            }
            else if member2.memberUID == userUID {
                return false
            }
            else if member1.memberUID == hostUID {
                return true
            }
            else if member2.memberUID == hostUID {
                return false
            }
            else {
                return member1.memberName ?? "" < member2.memberName ?? ""
            }
        }
    }
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
                    ForEach(sortedMembers, id: \.memberUID) { member in
                    MemberItemView(meetingID: meetingID, member: member, hostUID: hostUID, userUID: userUID)
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
                    HStack {
                            Circle()
                            .fill(Color.gray)
                            .frame(width: 20, height: 20)
                            .overlay(Text("나").foregroundColor(.white).font(.caption))
                            Text("- \(member.memberName ?? "")")
                                .font(.body)
                    }
                }
                else if(member.memberUID == hostUID){
                    Text("방장 - \(member.memberName ?? "")")
                        .font(.body)
                }
                else {
                    Text(member.memberName ?? "")
                        .font(.body)
                }
                Spacer()
            }
            .sheet(isPresented: $isShowMember){
                ProfilePreview(user: User(id: member.memberUID, userName: member.memberName ?? "", userImage: member.memberImage), isCurrent: member.memberUID == viewModel.currentUID, showChatButton: true)
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
    let isContinuousFromLastMessage: Bool
    

    var body: some View {
        HStack(spacing:10){
            if(identifying==false){
                if (isContinuousFromLastMessage==false){
                    WebImage(url: member.memberImage).placeholder{ProgressView()}
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .padding(.leading,5)
                    VStack(alignment:.leading,spacing: 0, content: {
                        NickName(name: member.memberName ?? "")
                            .padding(.leading, 10)
                        HStack{
                            if let imageUrl = message.imageUrl, imageUrl != "" {
                                                        FirebaseImageView(imageUrl: imageUrl)
                                                            .frame(maxWidth: 200)
                                                            .cornerRadius(10)
                                                            .padding(5)
                                                    } else {
                                                        Text(message.text)
                                                            .fontWeight(.semibold)
                                                            .foregroundColor(.white)
                                                            .padding()
                                                            .background(Color.blue.clipShape(ChatBubble()))
                                                            .padding(5)
                                                    }
                            VStack{
                                Spacer()
                                    .frame(width: 5)
                                Text(formatTimestamp(message.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(.leading,-5)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(.leading, -10)
                        .frame(maxWidth: 300)
                    }
                    )
                    Spacer()
                }
                else{
                    HStack(){
                        Spacer()
                            .frame(width: 18)
                        if let imageUrl = message.imageUrl, imageUrl != "" {
                                                 FirebaseImageView(imageUrl: imageUrl)
                                                     .frame(maxWidth: 200)
                                                     .cornerRadius(10)
                                                     .padding(5)
                                             } else {
                                                 Text(message.text)
                                                     .fontWeight(.semibold)
                                                     .foregroundColor(.white)
                                                     .padding()
                                                     .background(Color.blue.clipShape(ContinuousChatBubble()))
                                                     .padding(5)
                                }
                        VStack{
                            Spacer()
                                .frame(width: 5)
                            Text(formatTimestamp(message.timestamp))
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .padding(.leading,-5)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.leading, -10)
                    .frame(maxWidth: 300)

                }
            }
            
            else{
                if(isContinuousFromLastMessage){
                    Spacer()
                    HStack{
                        Spacer()
                        VStack{
                            Spacer()
                                .frame(width: 5)
                            Text(formatTimestamp(message.timestamp))
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .padding(.trailing,-8)
                            Spacer()
                        }
                        
                        if let imageUrl = message.imageUrl, imageUrl != "" {
                                                  FirebaseImageView(imageUrl: imageUrl)
                                                      .frame(maxWidth: 200)
                                                      .cornerRadius(10)
                                                      .padding(5)
                                              } else {
                                                  Text(message.text)
                                                      .fontWeight(.semibold)
                                                      .foregroundColor(.black)
                                                      .padding()
                                                      .background(Color("lightgray").clipShape(ContinuousChatBubble()))
                                                      .padding(5)
                                              }
                    }
                    .frame(maxWidth:300)
                }
                else{
                    Spacer()
                    HStack{
                        Spacer()
                        VStack{
                            Spacer()
                                .frame(width: 5)
                            Text(formatTimestamp(message.timestamp))
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .padding(.trailing,-8)
                            Spacer()
                        }
                        if let imageUrl = message.imageUrl, imageUrl != "" {
                                                  FirebaseImageView(imageUrl: imageUrl)
                                                      .frame(maxWidth: 200)
                                                      .cornerRadius(10)
                                                      .padding(5)
                                              } else {
                                                  Text(message.text)
                                                      .fontWeight(.semibold)
                                                      .foregroundColor(.black)
                                                      .padding()
                                                      .background(Color("lightgray").clipShape(MyChatBubble()))
                                                      .padding(5)
                                              }
                    }
                    .frame(maxWidth:300)
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

struct FirebaseImageView: View {
    @ObservedObject var imageLoader: FirebaseImageLoader
   
    
    init(imageUrl: String) {
           self.imageLoader = FirebaseImageLoader(imageUrl: imageUrl)
       }
    
    var body: some View {
        if let image = self.imageLoader.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            ProgressView()
                .scaledToFit()
                .frame(width:200,height:200)
        }
    }
}


struct ChatBubble: Shape {
    func path(in rect: CGRect) -> Path{
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft,.topRight,.bottomRight],cornerRadii: CGSize(width: 15, height: 15))
        
        return Path(path.cgPath)
    }
}

struct ContinuousChatBubble: Shape {
    func path(in rect: CGRect) -> Path{
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft,.topRight,.bottomLeft,.bottomRight],cornerRadii: CGSize(width: 15, height: 15))
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
    
    var body: some View {
        ZStack(alignment: .leading){
            if(text.isEmpty){
                placeholder
                    .opacity(0.5)
            }
            TextField("",text:$text)
                .frame(maxWidth: 250)
        }
        .padding(13)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}



