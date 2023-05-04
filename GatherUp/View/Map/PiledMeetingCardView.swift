//
//  PiledMeetingCardView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/04.
//

import SwiftUI
import SDWebImageSwiftUI

struct PiledMeetingCardView: View {
    var meeting: Meeting
    
    var body: some View {
        HStack(spacing: 12){
            WebImage(url: meeting.hostImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            Text(meeting.title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .frame(width: 100)
                .lineLimit(2)
                
            
            VStack(alignment: .leading){
                Text(meeting.hostName)
                    .foregroundColor(.black)
                Text(meeting.meetingDate.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            /*
            Text(meeting.publishedDate.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(.gray)
            */
            Text(meeting.description)
                .textSelection(.enabled)
                .foregroundColor(.black)
                .lineLimit(3)
             
        }
        .hAlign(.leading)
    }
}

