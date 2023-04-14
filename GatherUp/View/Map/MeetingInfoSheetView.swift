//
//  MeetingInfoSheetView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/14.
//

import SwiftUI
import CoreLocation
import Firebase
import SDWebImageSwiftUI

struct MeetingInfoSheetView: View {
    
    @StateObject var servermodel: FirebaseViewModel = .init()
    var meeting: Meeting
    
    var body: some View {
        VStack{
              HStack{
                  WebImage(url: meeting.hostImage)
                      .resizable()
                      .scaledToFit()
                      .frame(width:30,height: 30)
                      .font(.headline)
                      .foregroundColor(.white)
                      .padding(6)
                      .background(.blue)
                      .clipShape(Circle())
                  Text(meeting.publishedDate.formatted(date: .abbreviated, time: .shortened))
                      .font(.caption2)
                      .padding(.leading)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding()
              Spacer()
            Text(meeting.title)
            Text(meeting.description)
            Text(meeting.meetingDate.formatted(date: .abbreviated, time: .shortened))
            Text("\(meeting.numbersOfMembers)")
            Button{
                servermodel.joinMeeting(meetingId: meeting.id!)
            } label: {
                Text("참여하기")
            }
          }
    }
}
//
//struct MeetingInfoSheetView_Previews: PreviewProvider {
//    static var previews: some View {
//        MeetingInfoSheetView()
//    }
//}

