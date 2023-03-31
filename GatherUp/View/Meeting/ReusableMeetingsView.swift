//
//  ReusableMeetingsView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import Firebase

struct ReusableMeetingsView: View {
    @Binding var meetings: [Meeting]
    /// - View Properties
    @State var isFetching: Bool = true
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top,30)
                }else{
                    if meetings.isEmpty{
                        /// No Meeting's Found on Firestore
                        Text("No Meeting's Found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top,30)
                    }else{
                        /// - Displaying Meeting's
                        Meetings()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            /// - Scroll to Refresh
            isFetching = true
            meetings = []
            await fetchMeetings()
        }
        .task {
            /// - Fetching For One Time
            guard meetings.isEmpty else{return}
            await fetchMeetings()
        }
    }
    
    /// - Displaying Fetched Meeting's
    @ViewBuilder
    func Meetings()->some View{
        ForEach(meetings){meeting in
            MeetingCardView(meeting: meeting) { updatedMeeting in
                /// Updating Meeting in the Array
                if let index = meetings.firstIndex(where: { meeting in
                    meeting.id == updatedMeeting.id
                })
                {
//                    meetings[index].likedIDs = updatedMeeting.likedIDs
//                    meetings[index].dislikedIDs = updatedMeeting.dislikedIDs
                }
            } onDelete: {
                /// Removing Meeting From The Array
                withAnimation(.easeInOut(duration: 0.25)){
                    meetings.removeAll{meeting.id == $0.id}
                }

            }
            
            Divider()
                .padding(.horizontal,-15)
        }
    }
    
    /// - Fetching Meeting's
    func fetchMeetings()async{
        do{
            var query: Query!
            query = Firestore.firestore().collection("Meetings")
                .order(by: "publishedDate", descending: true)
                .limit(to: 20)
            let docs = try await query.getDocuments()
            let fetchedMeetings = docs.documents.compactMap{ doc -> Meeting? in
                try? doc.data(as: Meeting.self)
            }
            await MainActor.run(body: {
                meetings = fetchedMeetings
                isFetching = false
            })
        }catch{
            print(error.localizedDescription)
        }
    }
}

struct ReusableMeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
