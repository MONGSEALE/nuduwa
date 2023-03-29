//
//  ContentView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
   
    var body: some View {
        
        // 로그인변수가 false면 Login뷰로 이동
        if //logStatus {
        true{   // 로그인 되면 이 줄 삭제
            TabView{
               MapView()
                    .tabItem{
                        Label("Map",systemImage:"map.circle")
                    }
                MeetingsView()
                    .tabItem{
                        Label("Meetings",systemImage: "person.3.sequence")
                    }
            
                ProfileView()
                    .tabItem{
                        Label("Profile",systemImage:"person.crop.circle")
                    }
                }
        } else {
            Login()
        }
      
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



