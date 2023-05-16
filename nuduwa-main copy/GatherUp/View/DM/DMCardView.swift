//
//  DMCardView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth

struct DMCardView: View {
    
    @StateObject var viewModel: DMViewModel = .init()
    
    let chattingRoom: Chatter
    
    /// - Callbacks
    //    var onUpdate: (DM)->()
    
    var body: some View {
        HStack(spacing: 16) {
            WebImage(url: viewModel.user?.userImage).placeholder{ProgressView()}
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(RoundedRectangle(cornerRadius: 44)
                    .stroke(Color.black, lineWidth: 1))
            VStack(alignment: .leading) {
                Text(viewModel.user?.userName ?? "")
                    .font(.system(size: 16, weight: .bold))
                Text(viewModel.messages.last?.message ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.lightGray))
                
            }
           
            Spacer()
            if chattingRoom.unreadMessages > 0 {
                           Text("\(chattingRoom.unreadMessages)")
                       .foregroundColor(.white)
                       .padding(10)
                       .background(
                        Circle()
                                   .fill(Color.red)
                        )
                       }
            Spacer()
                .frame(width: 12)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear{
            viewModel.fetchUser(userUID: chattingRoom.chatterUID)
            viewModel.startListeningDM(senderID: viewModel.currentUID!, receiverID: chattingRoom.chatterUID)
        }
        .onDisappear{
            viewModel.removeListener()
        }
    }
}
