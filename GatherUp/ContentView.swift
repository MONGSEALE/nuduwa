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
    @State private var showDMView = false
    @State private var selectedReceiverID: String = ""
    @State private var selectedReceiverName: String = ""
   
    var body: some View {
        ZStack{
            if isLoading {
                Splash()
            }else{
                // 로그인변수가 false면 Login뷰로 이동
                if loginViewModel.isLogin {
                    ZStack{
                        TabView{
                            MapView()
                                .tabItem{
                                    Label("찾기",systemImage:"map.circle")
                                }
                            MeetingsView()
                                .tabItem{
                                    Label("모임",systemImage: "person.3.sequence")
                                }
                            DMListView(showDMView: $showDMView,selectedReceiverID: $selectedReceiverID,selectedReceiverName: $selectedReceiverName)
                                .tabItem{
                                    Label("채팅",systemImage: "message")
                                }
                            ProfileView()
                                .tabItem{
                                    Label("내 정보",systemImage:"person.crop.circle")
                                }
                        }
                        if showDMView {
                            DMView(senderID: loginViewModel.currentUID, receiverID: selectedReceiverID, showDMView: $showDMView)
                                 .edgesIgnoringSafeArea(.all)
                                 .transition(.move(edge: .bottom))
                         }
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


