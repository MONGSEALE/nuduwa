//
//  MeetingCardView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import SDWebImageSwiftUI

struct MeetingCardView: View {
    
    // @StateObject var viewModel: MeetingViewModel = .init()
    @ObservedObject var viewModel: MeetingViewModel //수정
    
    // var meeting: Meeting
    let meetingID: String
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
            }
            
            if meeting.hostUID == viewModel.currentUID ?? ""{
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
            // viewModel.meeting = meeting
            viewModel.fetchUserData(meeting.hostUID)
            // viewModel.meetingListener(meetingID: meeting.id!)
            viewModel.meetingListener(meetingID: meetingID)
        }
        .onDisappear {
            // 클릭해서 DetailMeetingView가 보여질 때는 removeListener() 호출하지 않음
            if !viewModel.isDetailViewVisible {
                viewModel.removeListener()
            }
        }
        // .onChange(of: viewModel.meeting) { updatedMeeting in
        //     if let updatedMeeting {
        //         if updatedMeeting.hostUID != "" {
        //             onUpdate(updatedMeeting)
        //         }
        //     }
        // }
        // .onChange(of: viewModel.deletedMeeting) { _ in
        //     onDelete()
        // }
    }
}
