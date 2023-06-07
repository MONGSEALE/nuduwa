//
//  MeetingInfoSheetView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/14.
//

import SwiftUI
import CoreLocation
import SDWebImageSwiftUI

struct MeetingInfoSheetView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: MeetingViewModel = .init()
    @State var showMessage = false

    let meeting: Meeting

    var body: some View {
        let meeting = viewModel.meeting ?? meeting
        GeometryReader { geometry in
            VStack {
                ZStack {
                    Capsule()
                        .frame(width: 40, height: 6)
                }
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.00001))
                
                HStack {
                    WebImage(url: viewModel.user?.userImage).placeholder{ProgressView()}
                        .resizable()
                        .frame(width: 100, height: 100) // Adjust these values to resize the WebImage
                        .scaledToFit()
                        .cornerRadius(60)
                        .clipShape(Circle())
                    VStack(alignment: .leading) {
                        Text(viewModel.user?.userName ?? "")
                            .font(.system(size:20))
                        Text("\(meeting.publishedDate.formatted(.dateTime.hour().minute()))에 생성됨")
                            .font(.caption2)
                    }
                    .padding(.leading,20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                Spacer()
                HStack{
                    Text(meeting.title)
                        .padding(.bottom, geometry.size.height <= 200 ? 0 : 8)
                        .font(.system(size:24))
                    Spacer()
                }
                .padding(.leading, 30)
                if geometry.size.height > 310 {
                    Spacer()
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .padding(.leading,30)
                        Text(meeting.place)
                        
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Image(systemName: "highlighter")
                            .padding(.leading,30)
                        Text(meeting.description)
                        
                        Spacer()
                    }
                    Spacer()
                    HStack{
                        Image(systemName: "calendar")
                            .padding(.leading,30)
                        Text("\(meeting.meetingDate.formatted(.dateTime.month().day().hour().minute()))에 만날꺼에요!")
                        Spacer()
                    }
                    
                    Spacer()
                    HStack{
                        Image(systemName: "person.2")
                            .padding(.leading,30)
                        Text("참여인원 ")
                        if let numbersOfMembers = viewModel.meeting?.numbersOfMembers{
                            Text("\(viewModel.members.count)/\(numbersOfMembers)")
                        }else{
                            ProgressView()
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    if let numbersOfMembers = viewModel.meeting?.numbersOfMembers{
                        if viewModel.currentUID != meeting.hostUID{  // host가 아니면
                            if viewModel.members.first(where: { $0.memberUID == viewModel.currentUID}) == nil{  // members 배열에 user가 없으면
                                if viewModel.members.count<numbersOfMembers {  // 모임에 자리가 있으면
                                    Button {
                                        viewModel.joinMeeting(meetingID: meeting.id!, meetingDate: meeting.meetingDate, hostUID: meeting.hostUID,numbersOfMembers: 10)
                                    } label: {
                                        Text("참여하기")
                                    }
                                } else {  // 모임에 자리가 없으면
                                    Text("참여불가")
                                }
                            } else {  // members 배열에 user가 있으면
                                Text("참여중")
                            }
                        }
                    } else {
                        ProgressView()
                    }
                    
                }
                
            }
            
        }
        .onAppear {
            viewModel.fetchUser(meeting.hostUID)
            viewModel.meetingListener(meetingID: meeting.id!)
            viewModel.membersListener(meetingID: meeting.id!)
        }
        .onDisappear{
            viewModel.removeListeners()
        }
        .onChange(of: viewModel.meeting) { meeting in
            if meeting == nil {
                dismiss()
            }
        }
        .onChange(of: viewModel.members) { _ in
                //멤버 나갈시 뷰 재생성
        }
    }
}






