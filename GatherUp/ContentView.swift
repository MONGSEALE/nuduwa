//
//  ContentView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    @State var isLoading: Bool = true
   
    var body: some View {
        ZStack{
            // 로그인변수가 false면 Login뷰로 이동
            if logStatus {
                TabView{
                    MapView()
                        .tabItem{
                            Label("찾기",systemImage:"map.circle")
                        }
                    MeetingsView()
                        .tabItem{
                            Label("모임",systemImage: "person.3.sequence")
                        }
                    
                    ProfileView()
                        .tabItem{
                            Label("내 정보",systemImage:"person.crop.circle")
                        }
                }
            } else {
                Login()
            }
            
            if isLoading {
                Splash()
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


