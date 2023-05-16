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
    
    @State  var selectedReceiverID: String = ""
    @State  var isDMViewPresented = false
    
    var body: some View {
        ZStack{
            if isLoading {
                Splash()
            }else{
                // 로그인변수가 false면 Login뷰로 이동
                if loginViewModel.isLogin {
                  
                    if(isDMViewPresented == false){
                        TabView(){
                            MapView()
                                .tabItem{
                                    Label("찾기",systemImage:"map.circle")
                                }
                            MeetingsView()
                                .tabItem{
                                    Label("모임",systemImage: "person.3.sequence")
                                }
                            DMListView(selectedReceiverID:$selectedReceiverID , isDMViewPresented : $isDMViewPresented)
                                .tabItem{
                                    Label("채팅",systemImage: "message")
                                }
                            ProfileView()
                                .tabItem{
                                    Label("내 정보",systemImage:"person.crop.circle")
                                }
                        }
                    }
                    else{
                            DMView(receiverID: selectedReceiverID,isDMViewPresented: $isDMViewPresented)
                            .edgesIgnoringSafeArea(.all)
                            .transition(.move(edge: .trailing))
                            .animation(.easeInOut(duration: 0.3))
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





