//
//  ReusableMeetingsView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI
import Firebase

struct ReusableMeetingsView: View {
    @StateObject var viewModel: MeetingViewModel = .init()
    var title: String = ""
    var passedMeeting: Bool = false
    
    var body: some View {
        NavigationStack{
            if viewModel.isFetching{
                ProgressView()
                    .padding(.top,30)
            } else {
                if viewModel.meetings.isEmpty{
                    /// 모임 배열이 비어있을때
                    Text("가입한 모임이 없습니다")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top,30)
                }else{
                    ScrollView{
                        ForEach(viewModel.meetings){ meeting in
                            NavigationLink(value: meeting){
                                MeetingCardView(meeting: meeting) { updatedMeeting in
                                    /// 모임 내용이 업데이트 되었을때 viewModel.meetings 배열값을 수정하여 실시간 업데이트
                                    if let index = viewModel.meetings.firstIndex(where: { meeting in
                                        meeting.id == updatedMeeting.id
                                    })
                                    {
                                        viewModel.meetings[index].title = updatedMeeting.title
                                        viewModel.meetings[index].description = updatedMeeting.description
                                    }
                                } onDelete: {
                                    /// 모임이 삭제되었을때 실시간 삭제
                                    withAnimation(.easeInOut(duration: 0.25)){
                                        viewModel.meetings.removeAll{meeting.id == $0.id}
                                    }
                                }
                            }
                            Divider()
                        }
                        .navigationDestination(for: Meeting.self) { meeting in
                            /// 리스트에서 모임 클릭시 이동
                            DetailMeetingView(meeting: meeting)
                        }
                        .navigationTitle(title)
                        .navigationBarTitleDisplayMode(.inline)
                        .listStyle(.plain)
                    }
                    .padding(15)
                }
            }
        }
        .onAppear{
            viewModel.meetingsListner(isJoin: true)
        }
        .onDisappear{
            viewModel.removeListner()
        }
    }
}


struct ReusableMeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
