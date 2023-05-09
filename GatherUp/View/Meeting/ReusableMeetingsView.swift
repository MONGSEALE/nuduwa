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
    let title: String
    var passedMeeting: Bool = false
    
    var body: some View {
        NavigationStack{
            if viewModel.isLoading{
                /// 모임데이터 가져오는 중일때
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
                            NavigationLink(destination: DetailMeetingView(meeting: meeting)){
                                MeetingCardView(meeting: meeting) { updatedMeeting in
                                    /// 모임 내용이 업데이트 되었을때 viewModel.meetings 배열값을 수정하여 실시간 업데이트
                                    viewModel.updateLocalMeetingDataFromServer(updatedMeeting: updatedMeeting)
                                } onDelete: {
                                    /// 모임이 삭제되었을때 실시간 삭제
                                    withAnimation(.easeInOut(duration: 0.25)){
                                        viewModel.deleteLocalMeetingDataFromServer(deletedMeetingID: meeting.id!)
                                    }
                                }
                            }
                            Divider()
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
            viewModel.meetingsListener()
        }
    }
}


struct ReusableMeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

