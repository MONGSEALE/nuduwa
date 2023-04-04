//
//  DetailMeetingView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/04.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct DetailMeetingView: View {
    var meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                HStack(spacing: 12){
                    WebImage(url: meeting.userImage).placeholder{
                        // MARK: Placeholder Image
                        Image("NullProfile")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6){
                        Text(meeting.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(meeting.userName)
                            .font(.callout)
                        Text(meeting.publishedDate.formatted(date: .numeric, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .hAlign(.leading)
                }
                Text(meeting.description)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                    .hAlign(.leading)
            }
            .padding(15)
        }
        if meeting.userUID == Auth.auth().currentUser?.uid {
            Button(/*role: .destructive, */action: deleteMeeting){
                Text("Delete Meeting")
                    .font(.callout)
                    .foregroundColor(.white)
                    .padding(.horizontal,30)
                    .padding(.vertical,10)
                    .background(.red,in: Capsule())
            }
            .frame(alignment: .bottom)
            .padding(15)
            //.offset(y: 18)
        }
        
    }
    
    /// - Deleting Meeting
    func deleteMeeting(){
        Task{
            do{
                /// Delete Firestore Document
                guard let meetingID = meeting.id else{return}
                try await Firestore.firestore().collection("Meetings").document(meetingID).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
        dismiss()
    }
}
