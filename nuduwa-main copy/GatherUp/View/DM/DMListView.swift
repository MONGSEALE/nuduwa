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
    
    @Binding var showDMView: Bool
    @Binding var selectedReceiverID: String
    
    
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
                                        showDMView = true
                                    }
                                    .padding(.bottom,5)
                                Divider()
//                             .contextMenu {
//                                 Button(action: {
//                                          viewModel.deleteRecentMessage(receiverID: receiverID)
//                                 }) {
//                                 Label("채팅방 나가기", systemImage: "trash")
//                                 }
//                             }
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


