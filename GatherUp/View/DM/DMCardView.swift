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
//    var showDMView: (String?)->()
    
    @Binding var receiverUID: String?
    @Binding var showDMView: Bool
    
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
                Text(viewModel.messages.first?.text ?? "")
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
        .onTapGesture {
            receiverUID = chattingRoom.receiverUID
            showDMView = true
        }
        .contextMenu { // 길게 눌렀을 때 표시할 메뉴
            Button(action: {
                viewModel.leaveChatroom(receiverUID: chattingRoom.receiverUID) // 채팅방 나가기 메뉴 선택 시 처리
            }) {
                Text("채팅방 나가기")
                Image(systemName: "trash")
            }
        }
        .onAppear{
            viewModel.fetchUser(chattingRoom.receiverUID)
            viewModel.dmListener(dmPeopleRef: chattingRoom.dmPeopleRef, listenerKey: chattingRoom.receiverUID)
        }
        .onDisappear{
            viewModel.removeListeners()
        }
    }
        
}
