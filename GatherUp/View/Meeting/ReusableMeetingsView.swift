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
    @StateObject var viewModel: MeetingViewModel = .init()
    var basedOnMeeting: Bool = false
    
    var body: some View {
        NavigationView{//(.vertical, showsIndicators: false) {
            if viewModel.isFetching{
                ProgressView()
                    .padding(.top,30)
            }else{
                if viewModel.meetingsFirestore.isEmpty{
                    /// No Meeting's Found on Firestore
                    Text("가입한 모임이 없습니다")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top,30)
                }else{
                    /// - Displaying Meeting's
                    List(viewModel.meetingsFirestore){ meeting in
                        NavigationLink(destination: DetailMeetingView(meeting: meeting)){
                            MeetingCardView(meeting: meeting) { updatedMeeting in
                                /// Updating Meeting in the Array
                                if let index = viewModel.meetingsFirestore.firstIndex(where: { meeting in
                                    meeting.id == updatedMeeting.id
                                })
                                {
                                    viewModel.meetingsFirestore[index].description = updatedMeeting.description
                                }
                            } onDelete: {
                                /// Removing Meeting From The Array
                                withAnimation(.easeInOut(duration: 0.25)){
                                    viewModel.meetingsFirestore.removeAll{meeting.id == $0.id}
                                }
                            }
                            .onAppear {
                                /// - When Last Post Appears, Fetching New Post (If There)
                                if meeting.id == viewModel.meetingsFirestore.last?.id && viewModel.paginationDoc != nil{
                                    Task{await viewModel.fetchMeetings()}
                                }
                            }
                        }
                    }
                    .navigationTitle("내 모임")
                    .listStyle(.plain)
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            //.padding(15)
        }
        .refreshable {
            /// - Scroll to Refresh
            viewModel.isFetching = true
            viewModel.meetingsFirestore = []
            /// - Resetting Pagination Doc
            viewModel.paginationDoc = nil
            await viewModel.fetchMeetings()
        }
        .task {
            /// - Fetching For One Time
            guard viewModel.meetingsFirestore.isEmpty else{return}
            await viewModel.fetchMeetings()
        }
    }
}

struct ReusableMeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
