//
//  MeetingsView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI

struct MeetingsView: View {
    @State private var recentsMeetings: [Meeting] = []
    @State private var createNewMeeting: Bool = false
    var body: some View {
        NavigationStack{
            ReusableMeetingsView(meetings: $recentsMeetings)
                .hAlign(.center).vAlign(.center)
                .overlay(alignment: .bottomTrailing){
                    Button{
                        createNewMeeting.toggle()
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
        .fullScreenCover(isPresented: $createNewMeeting) {
//            CreateNewPost { post in
//                /// - Adding Created post at the Top of the Recent Posts
//                recentsMeetings.insert(post, at: 0)
//            }
        }
    }
}

struct MeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingsView()
    }
}
