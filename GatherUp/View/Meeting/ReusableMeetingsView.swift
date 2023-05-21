//
//  ReusableMeetingsView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/03/31.
//

import SwiftUI

struct ReusableMeetingsView: View {
    @StateObject var viewModel: MeetingViewModel = .init()
    let title: String
    
    var body: some View {
        NavigationStack{
            if viewModel.isLoading{
                /// 모임데이터 가져오는 중일때
                ProgressView()
                    .padding(.top,30)
            } else {
                if viewModel.userMeetings.isEmpty{
                    /// 모임 배열이 비어있을때
                    Text("가입한 모임이 없습니다")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top,30)
                }else{
                    ScrollView{
                        ForEach(viewModel.userMeetings){ userMeeting in
                            let sharedViewModel: MeetingViewModel = .init() //수정
                            NavigationLink(
                                destination: DetailMeetingView(meetingID: userMeeting.meetingID, viewModel: sharedViewModel)
                            ){
                                MeetingCardView(meetingID: userMeeting.meetingID, viewModel: sharedViewModel) 
                                // { updatedMeeting in
                                //     /// 모임 내용이 업데이트 되었을때 viewModel.meetings 배열값을 수정하여 실시간 업데이트
                                //     viewModel.updateLocalMeetingDataFromServer(updatedMeeting: updatedMeeting)
                                // } onDelete: {
                                //     /// 모임이 삭제되었을때 실시간 삭제
                                //     withAnimation(.easeInOut(duration: 0.25)){
                                //         viewModel.deleteLocalMeetingDataFromServer(deletedMeetingID: meeting.id!)
                                //     }
                                // }
                                .onTapGesture {
                                    // 클릭시 MeetingCardView의 .onDisappear가 호출되기 전에 수행할 동작
                                    sharedViewModel.detailViewAppear()
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
            // viewModel.meetingsListener()
            viewModel.userMeetingsListener()
        }
    }
}


struct ReusableMeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

