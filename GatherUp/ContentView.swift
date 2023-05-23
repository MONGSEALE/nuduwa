//
//  ContentView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI

struct ContentView: View {
    @StateObject var loginViewModel: LoginViewModel = .init()
    @State var isLoading: Bool = true
    @State var receiverID: String?
    @State var showDMView: Bool = false
   
    var body: some View {
        ZStack{
            if isLoading {
                Splash()
            }else{
                // 로그인변수가 false면 Login뷰로 이동
                if loginViewModel.isLogin {
                    TabView{
                        MapView()
                            .tabItem{
                                Label("찾기",systemImage:"map.circle")
                            }
                        MeetingsView()
                            .tabItem{
                                Label("모임",systemImage: "person.3.sequence")
                            }
                        DMListView(receiverID: $receiverID, showDMView: $showDMView)
                            .tabItem{
                                Label("채팅",systemImage: "message")
                            }
                        ProfileView()
                            .tabItem{
                                Label("내 정보",systemImage:"person.crop.circle")
                            }
                    }
                    .fullScreenCover(isPresented: $showDMView){
//                            DMView(receiverID: room.receiverUID, dmPeopleDocRef: room.dmPeopleRef, showDMView: $showDMView)
                        DMView(receiverID: $receiverID,  showDMView: $showDMView)
                        
                    }
                } else {
                    Login()
                }
            }
        }
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {isLoading.toggle()
                })
        }
    }
}


