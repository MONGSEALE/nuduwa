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
                            let itemViewModel: MeetingViewModel = .init() //수정
                            NavigationLink(
                                destination: DetailMeetingView(viewModel: itemViewModel, meetingID: userMeeting.meetingID)
                            ){
                                MeetingCardView(meeting: itemViewModel.meeting, isHost: itemViewModel.meeting?.hostUID == viewModel.currentUID)
                                    .onAppear {
                                        viewModel.meetingListener(meetingID: userMeeting.meetingID)
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
            viewModel.userMeetingsListener()
        }
    }
}


struct ReusableMeetingsView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

