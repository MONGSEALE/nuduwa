//
//  MeetingCardView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct MeetingCardView: View {
    
    var meeting: Meeting
    /// - Callbacks
    var onUpdate: (Meeting)->()
    var onDelete: ()->()
    
    /// - View
    @State private var docListner: ListenerRegistration?
    
    //@State private var fetchedPosts: [Meeting] = []
    
    
    var body: some View {
        HStack(alignment: .top, spacing: 12){
            WebImage(url: meeting.hostImage)
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
                Text(meeting.hostName)
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
            /// - Adding Only Once
            if docListner == nil{
                guard let meetingID = meeting.id else{return}
                docListner = Firestore.firestore().collection("Meetings").document(meetingID).addSnapshotListener({ snapshot, error in
                    if let snapshot{
                        if snapshot.exists{
                            /// - Document Updated
                            /// Fetching Updated Document
                            if let updatedMeeting = try? snapshot.data(as: Meeting.self){
                                onUpdate(updatedMeeting)
                            }
                        }else{
                            /// - Document Deleted
                            onDelete()
                        }
                    }
                })
            }
            
             
        }
        .onDisappear {
            // 화면 보는동안만 실시간 동기화
            if let docListner{
                docListner.remove()
                self.docListner = nil
            }
             
        }
        
    }
}
