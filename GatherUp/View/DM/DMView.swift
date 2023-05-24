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
    @Binding var showDMView: Bool
    @State private var count: Int = 0 //테스트용 변수
    
    var body: some View {
        if let receiverID {
            NavigationView{ //NavigationView 필요없으면 제거
                VStack {                    
                    ScrollView{
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.messages.indices, id: \.self) { index in
                                // index = 0 이 제일 최신 메시지
                                let message = viewModel.messages[index]
                                // 마지막 메시지면 nil 아니면 전 메시지 출력
                                let previousMessage = message==viewModel.messages.last ? nil : viewModel.messages[index + 1]

                                let isCurrentUser = message.senderUID == viewModel.currentUID

                                DMMessageRow(message: message, identifying: isCurrentUser, name: viewModel.user?.userName, image: viewModel.user?.userImage).flippedUpsideDown()
                                    .onAppear {
                                        count += 1
                                        print("온어피어호출수:\(count)")
                                        print("messageCount:\(viewModel.messages.count)")

                                        if message.id == viewModel.messages.last?.id && viewModel.paginationDoc != nil  {
                                            guard let docRef = viewModel.dmPeopleRef else{return}
                                            viewModel.fetchPrevMessage(dmPeopleRef: docRef)
                                        }
                                    }
                                
                                // 날짜 출력
                                if isNewDay(previousMessage: previousMessage, currentMessage: message) {
                                    Text(formatDate(message.timestamp)).flippedUpsideDown()
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.top)
                                        .frame(maxWidth:.infinity)
                                }
                            }
                        }
                    }.flippedUpsideDown()
                    
                    Spacer()
                    HStack{
                        CustomTextFieldRow(placeholder: Text("메시지를 입력하세요"), text: $messageText)
                        Button{
                            if viewModel.dmPeopleRef != nil{
                                viewModel.sendDM(message: messageText)
                                messageText = ""
                            }
                        }label: {
                            if viewModel.dmPeopleRef != nil{
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color("lightblue"))
                                    .cornerRadius(50)
                            } else {
                                ProgressView()
                            }
                        }
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
                        showDMView = false
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
                viewModel.startListeningDM(chatterUID: receiverID)
                viewModel.fetchUserData(receiverID)
            }
            .onDisappear {
                print("바이")
                viewModel.fetchChatRoomID(receiverID: receiverID) { chatRoomID in
                    // 새로운 메시지가 도착하면 unreadMessages를 0으로 설정
                    guard let senderID = viewModel.currentUID else{return}
                    viewModel.resetUnreadMessages(userID: senderID, chatRoomID: chatRoomID)
                }
                viewModel.removeListeners()
            }
            
        }
    }
    func isNewDay(previousMessage: Message?, currentMessage: Message) -> Bool {
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
  
    @State var message : Message
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


struct FlippedUpsideDown: ViewModifier {
   func body(content: Content) -> some View {
    content
      .rotationEffect(Angle(radians: Double.pi))
      .scaleEffect(x: -1, y: 1, anchor: .center)
   }
}
extension View{
   func flippedUpsideDown() -> some View{
     self.modifier(FlippedUpsideDown())
   }
}
  
