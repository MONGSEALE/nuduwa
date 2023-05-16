//
//  DMListView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/11.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI

struct DMListView: View {
    
    @StateObject private var viewModel = DMViewModel()
    @State private var userImageURLs: [String: URL] = [:]
    @State private var tabBar : UITabBar! = nil
    
    
    @Binding var selectedReceiverID: String 
    
    @Binding var isDMViewPresented : Bool
    
    
    var body: some View {
        
        NavigationStack{
            if viewModel.isLoading{
                /// 데이터 가져오는 중일때
                ProgressView()
                    .padding(.top,30)
            } else {
                VStack{
                    HStack(spacing:16){
                        Spacer()
                            .frame(width: 16)
                        Text("채팅")
                            .font(.system(size: 24,weight: .bold))
                        Spacer()
                        Button{
                            
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                    .padding()
                    ScrollView {
                        if viewModel.chattingRooms.isEmpty{
                            /// 모임 배열이 비어있을때
                            Text("채팅이 없습니다")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top,30)
                        }else{
                            
                            ForEach(viewModel.chattingRooms) { chattingRoom in
                                DMCardView(chattingRoom: chattingRoom)
                                    .onTapGesture {
                                        selectedReceiverID = chattingRoom.chatterUID
                                        isDMViewPresented = true
                                    }
                                    .contextMenu { // 길게 눌렀을 때 표시할 메뉴
                                                           Button(action: {
                                                               viewModel.leaveChatroom(chatroom: chattingRoom) // 채팅방 나가기 메뉴 선택 시 처리
                                                           }) {
                                                               Text("채팅방 나가기")
                                                               Image(systemName: "trash")
                                                           }
                                                       }
                                    .padding(.bottom,5)
                                Divider()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .onAppear {
           viewModel.startListeningRecentMessages()
       }
    }
}


