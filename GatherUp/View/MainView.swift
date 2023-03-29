//
//  MainView.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/27.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        // MARK: TabView With Recent Post's And Profile Tabs
        TabView {
            PostsView()
                .tabItem {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                    Text("Post's")
                }
            //Text("Profile View")
            ProfileView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Profile")
                }
            GroupListView()
                .tabItem {
                    Image(systemName: "G.square.fill")
                    Text("GroupList")
                }
        }
        // Changing Tab Lable Tint to Black
        .tint(.black)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
