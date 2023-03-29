//
//  ContentView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI

struct ContentView: View {
   
    var body: some View {
        
      
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
        }
    }


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



