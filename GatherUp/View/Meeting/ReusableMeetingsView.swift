//
//  ReusableMeetingsView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import Firebase

struct ReusableMeetingsView: View {
    //@State var meetings: [Meeting] = []
    /// - View Properties
    //@State var isFetching: Bool = true
    /// - Pagination
    //@State private var paginationDoc: QueryDocumentSnapshot?
    @StateObject var firebaseViewModel: FirebaseViewModel = .init()
    
    var body: some View {
        NavigationView{//(.vertical, showsIndicators: false) {
            if firebaseViewModel.isFetching{
                ProgressView()
                    .padding(.top,30)
            }else{
                if firebaseViewModel.meetings.isEmpty{
                    /// No Meeting's Found on Firestore
                    Text("No Meeting's Found")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top,30)
                }else{
                    /// - Displaying Meeting's
                    List(firebaseViewModel.meetings){ meeting in
                        NavigationLink(destination: DetailMeetingView(meeting: meeting)){
                            MeetingCardView(meeting: meeting) { updatedMeeting in
                                /// Updating Meeting in the Array
                                if let index = firebaseViewModel.meetings.firstIndex(where: { meeting in
                                    meeting.id == updatedMeeting.id
                                })
                                {
                                    firebaseViewModel.meetings[index].description = updatedMeeting.description
                                }
                            } onDelete: {
                                /// Removing Meeting From The Array
                                withAnimation(.easeInOut(duration: 0.25)){
                                    firebaseViewModel.meetings.removeAll{meeting.id == $0.id}
                                }
                            }
                            .onAppear {
                                /// - When Last Post Appears, Fetching New Post (If There)
                                if meeting.id == firebaseViewModel.meetings.last?.id && firebaseViewModel.paginationDoc != nil{
                                    Task{await firebaseViewModel.fetchMeetings()}
                                }
                            }
                        }
                    }
                    .navigationTitle("Meeting's")
                    .listStyle(.plain)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            //.padding(15)
        }
        .refreshable {
            /// - Scroll to Refresh
            firebaseViewModel.isFetching = true
            firebaseViewModel.meetings = []
            /// - Resetting Pagination Doc
            firebaseViewModel.paginationDoc = nil
            await firebaseViewModel.fetchMeetings()
        }
        .task {
            /// - Fetching For One Time
            guard firebaseViewModel.meetings.isEmpty else{return}
            await firebaseViewModel.fetchMeetings()
        }
    }
    /*
    /// - Fetching Meeting's
    func fetchMeetings()async{
        do{
            var query: Query!
            /// - Implementing Pagination
            if (firebaseViewModel.paginationDoc != nil){
                query = Firestore.firestore().collection("Meetings")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: firebaseViewModel.paginationDoc!)
                    .limit(to: 20)
            }else{
                query = Firestore.firestore().collection("Meetings")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
            }
            let docs = try await query.getDocuments()
            let fetchedMeetings = docs.documents.compactMap{ doc -> Meeting? in
                try? doc.data(as: Meeting.self)
            }
            await MainActor.run(body: {
                //meetings = fetchedMeetings
                meetings.append(contentsOf: fetchedMeetings)
                firebaseViewModel.paginationDoc = docs.documents.last
                firebaseViewModel.isFetching = false
            })
        }catch{
            print(error.localizedDescription)
        }
    }
     */
}

struct ReusableMeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
