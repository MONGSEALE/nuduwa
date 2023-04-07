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
    var title: String = ""
    var passMeeting: Bool = false
    
    var body: some View {
        NavigationView{//(.vertical, showsIndicators: false) {
            if viewModel.isFetching{
                ProgressView()
                    .padding(.top,30)
            }else{
                if viewModel.meetings.isEmpty{
                    /// No Meeting's Found on Firestore
                    Text("가입한 모임이 없습니다")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top,30)
                }else{
                    /// - Displaying Meeting's
                    List(viewModel.meetings){ meeting in
                        NavigationLink(destination: DetailMeetingView(meeting: meeting)){
                            MeetingCardView(meeting: meeting) { updatedMeeting in
                                /// Updating Meeting in the Array
                                if let index = viewModel.meetings.firstIndex(where: { meeting in
                                    meeting.id == updatedMeeting.id
                                })
                                {
                                    viewModel.meetings[index].description = updatedMeeting.description
                                }
                            } onDelete: {
                                /// Removing Meeting From The Array
                                withAnimation(.easeInOut(duration: 0.25)){
                                    viewModel.meetings.removeAll{meeting.id == $0.id}
                                }
                            }
                            .onAppear {
                                /// - When Last Post Appears, Fetching New Post (If There)
                                if meeting.id == viewModel.meetings.last?.id && viewModel.paginationDoc != nil{
                                    Task{await viewModel.fetchMeetings(passMeeting: passMeeting)}
                                }
                            }
                        }
                    }
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .listStyle(.plain)
                }
            }
            //.padding(15)
        }
        .refreshable {
            /// - Scroll to Refresh
            viewModel.isFetching = true
            viewModel.meetings = []
            /// - Resetting Pagination Doc
            viewModel.paginationDoc = nil
            await viewModel.fetchMeetings(passMeeting: passMeeting)
        }
        .onAppear{
            viewModel.addMeetingsListner()
        }
        .onDisappear{
            viewModel.removeListner()
        }
        .task {
            /// - Fetching For One Time
            guard viewModel.meetings.isEmpty else{return}
            await viewModel.fetchMeetings(passMeeting: passMeeting)
        }
    }
}

struct ReusableMeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
