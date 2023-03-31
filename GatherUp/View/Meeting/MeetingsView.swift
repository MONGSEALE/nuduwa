//
//  MeetingsView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI

struct MeetingsView: View {
    @State private var recentsPosts: [Meeting] = []
    @State private var createNewPost: Bool = false
    var body: some View {
        NavigationStack{
            ReusableMeetingsView(posts: $recentsPosts)
                .hAlign(.center).vAlign(.center)
                .overlay(alignment: .bottomTrailing){
                    Button{
                        createNewPost.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(13)
                            .background(.black,in: Circle())
                    }
                    .padding(15)
                }
                .navigationTitle("Post's")
        }
        .fullScreenCover(isPresented: $createNewPost) {
//            CreateNewPost { post in
//                /// - Adding Created post at the Top of the Recent Posts
//                recentsPosts.insert(post, at: 0)
//            }
        }
        
        
        VStack(spacing:30){
            
            
            Text("This is meetings!")
                .underline()
            Text("meeting1...........................................")
                .underline()
            Text("meeting1...........................................")
                .underline()
            Text("meeting1...........................................")
                .underline()
            Text("meeting1...........................................")
                .underline()
            Text("meeting1...........................................")
                .underline()
            Text("meeting1...........................................")
                .underline()
            Text("meeting1...........................................")
                .underline()
            Text("meeting1...........................................")
                .underline()
            Text("meeting1...........................................")
                .underline()
        }
    }
}

struct MeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingsView()
    }
}
