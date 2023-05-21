//
//  PiledMeetingCardView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/04.
//

import SwiftUI
import SDWebImageSwiftUI

struct PiledMeetingCardView: View {
    
    @StateObject var viewModel: FirebaseViewModel = .init()

    let meeting: Meeting
    let isJoin: Bool
    
    var body: some View {
        let isHost = meeting.hostUID == viewModel.currentUID
        ZStack{
            HStack(spacing: 12){
                WebImage(url: viewModel.user?.userImage).placeholder{ProgressView()}
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .padding(4)
                    .background(Circle().fill(isHost ? .red : isJoin ? .green : .blue))
                
                Text(meeting.title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(width: 100)
                    .lineLimit(2)
                    
                
                VStack(alignment: .leading){
                    if let userName = viewModel.user?.userName {
                        Text(userName)
                            .lineLimit(1)
                            .foregroundColor(.black)
                    } else {
                        ProgressView()
                    }
                    Text(meeting.meetingDate.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Text(meeting.description)
                    .textSelection(.enabled)
                    .foregroundColor(.black)
                    .lineLimit(3)
            }
            .hAlign(.leading)
        }
        .onAppear{
            viewModel.fetchUser(meeting.hostUID)
        }
    }
}

