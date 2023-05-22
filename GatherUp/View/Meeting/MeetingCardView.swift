//
//  MeetingCardView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import SDWebImageSwiftUI

struct MeetingCardView: View {
    
    @StateObject var viewModel: MeetingViewModel = .init()
    //    @ObservedObject var viewModel: MeetingViewModel //수정
    
    let meetingID: String
    let hostUID: String
    //    let isHost: Bool
    //    let meetingID: String
    //    let hostUID: String
    /// - Callbacks
    // var onUpdate: (Meeting)->()
    // var onDelete: ()->()
    
    var body: some View {
        HStack(alignment: .top, spacing: 12){
            WebImage(url: viewModel.user?.userImage).placeholder{ProgressView()}
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6){
                if let meeting = viewModel.meeting {
                    HStack(){
                        Text(meeting.title)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        Text(meeting.meetingDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.callout)
                            .foregroundColor(.black)
                    }
                    Text(viewModel.user?.userName ?? "")
                        .font(.callout)
                        .foregroundColor(.black)
                    Text(meeting.publishedDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(meeting.description)
                        .textSelection(.enabled)
                        .padding(.vertical,8)
                        .foregroundColor(.black)
                } else {
                    ProgressView()
                }
            }
            
            if hostUID == viewModel.currentUID {
                VStack(){
                    Text("MINE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red)
                        )
                        .foregroundColor(.white)
                }
            }
            
        }
        .hAlign(.leading)
        
        .onAppear {
            viewModel.fetchUser(hostUID)
            viewModel.meetingListener(meetingID: meetingID)
        }
        //        .onDisappear {
        //            // 클릭해서 DetailMeetingView가 보여질 때는 removeListener() 호출하지 않음
        //            viewModel.removeListeners()
        //
        //        }
    
    }
}
