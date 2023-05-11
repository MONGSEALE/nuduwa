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
    
    var meeting: Meeting
    /// - Callbacks
    var onUpdate: (Meeting)->()
    var onDelete: ()->()
    
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
        }
        .hAlign(.leading)
        
        .onAppear {
            viewModel.meeting = meeting
            viewModel.fetchUser(userUID: meeting.hostUID)
            viewModel.meetingListener(meetingID: meeting.id!)
        }
        .onDisappear {
            viewModel.removeListener()
        }
        .onChange(of: viewModel.meeting) { updatedMeeting in
            if updatedMeeting.hostUID != "" {
                onUpdate(updatedMeeting)
            }
        }
        .onChange(of: viewModel.deletedMeeting) { _ in
            onDelete()
        }
    }
}
