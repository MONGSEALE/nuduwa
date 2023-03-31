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
    
    var body: some View {
        HStack(alignment: .top, spacing: 12){
            WebImage(url: meeting.userImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6){
                Text(meeting.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(meeting.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(meeting.text)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                
                if let postImageURL = meeting.imageURL{
                    GeometryReader{
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            /// Displaying Delete Button (if it's Author of that post)
            if post.userUID == Auth.auth().currentUser?.uid {
                Menu {
                    Button("Delete Post", role: .destructive, action: deletePost)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)
            }
        })
        .onAppear {
            /// - Adding Only Once
            if docListner == nil{
                guard let meetingID = meeting.id else{return}
                docListner = Firestore.firestore().collection("Meetings").document(meetingID).addSnapshotListener({ snapshot, error in
                    if let snapshot{
                        if snapshot.exists{
                            /// - Document Updated
                            /// Fetching Updated Document
                            if let updatedPost = try? snapshot.data(as: Meeting.self){
                                onUpdate(updatedPost)
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
            // MARK: Applying SnapShot Listner Only When the Post is Available on the Screen
            // Else Removing the Listner (It saves unwanted live updates from posts which was swiped away from the screen)
            // 화면 보는동안만 실시간 동기화 한다는 뜻인듯
            if let docListner{
                docListner.remove()
                self.docListner = nil
            }
        }
    }
    
    /// - Deleting Post
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
    }
}
