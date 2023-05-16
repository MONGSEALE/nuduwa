//
//  DMCardView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import SDWebImageSwiftUI

struct DMCardView: View {
    
    @StateObject var viewModel: DMViewModel = .init()
    
    let chattingRoom: DMList
    
    @State var showDM: Bool = false
    
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
                Text(viewModel.messages.last?.text ?? "")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.lightGray))
            }
            Spacer()
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            showDM = true
        }
        .contextMenu { // 길게 눌렀을 때 표시할 메뉴
            Button(action: {
                viewModel.leaveChatroom(chatroom: chattingRoom) // 채팅방 나가기 메뉴 선택 시 처리
            }) {
                Text("채팅방 나가기")
                Image(systemName: "trash")
            }
        }
        .onAppear{
            viewModel.fetchUserData(chattingRoom.chatterUID)
            viewModel.dmListener(dmPeopleID: chattingRoom.DMPeopleID)
        }
        .onDisappear{
            viewModel.removeListeners()
        }
        .fullScreenCover(isPresented: $showDM){
            DMView(receiverID: chattingRoom.chatterUID, : $showDM)
        }
    }
}
