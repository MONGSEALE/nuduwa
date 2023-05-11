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
    @StateObject var viewModel: MeetingInfoSheetViewModel = .init()
    @State var showMessage = false

    let meetingID: String
    let hostUID: String

    var body: some View {
        GeometryReader { geometry in
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top,30)
            }else{
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
                            Text("\(viewModel.meeting.publishedDate.formatted(.dateTime.hour().minute()))에 생성됨")
                                .font(.caption2)
                        }
                        .padding(.leading,20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    Spacer()
                    HStack{
                        Text(viewModel.meeting.title)
                            .padding(.bottom, geometry.size.height <= 200 ? 0 : 8)
                            .font(.system(size:24))
                    }
                    if geometry.size.height > 310 {
                        Spacer()
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .padding(.leading,30)
                            Text(viewModel.meeting.place)
                            
                            Spacer()
                        }
                        Spacer()
                        HStack {
                            Image(systemName: "highlighter")
                                .padding(.leading,30)
                            Text(viewModel.meeting.description)
                            
                            Spacer()
                        }
                        Spacer()
                        HStack{
                            Image(systemName: "calendar")
                                .padding(.leading,30)
                            Text("\(viewModel.meeting.meetingDate.formatted(.dateTime.month().day().hour().minute()))에 만날꺼에요!")
                            Spacer()
                        }
                        
                        Spacer()
                        HStack{
                            Image(systemName: "person.2")
                                .padding(.leading,30)
                            Text("참여인원  \(viewModel.members.count)/\(viewModel.meeting.numbersOfMembers)")
                            Spacer()
                        }
                        
                        Spacer()
                        
                        if viewModel.currentUID != viewModel.meeting.hostUID{  // host가 아니면
                            if viewModel.members.first(where: { $0.memberUID == viewModel.currentUID}) == nil{  // members 배열에 user가 없으면
                                if viewModel.members.count<viewModel.meeting.numbersOfMembers {  // 모임에 자리가 있으면
                                    Button {
                                        viewModel.joinMeeting(meetingID: viewModel.meeting.id!, numbersOfMembers: viewModel.meeting.numbersOfMembers)
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
                        
                    }
                }
            }
            
        }
        .onAppear {
            viewModel.fetchUser(userUID: hostUID)
            viewModel.meetingListner(meetingID: meetingID)
            viewModel.membersListener(meetingID: meetingID)
        }
        .onDisappear{
            viewModel.removeListener()
            viewModel.removeMeetingListener()
        }
        .onChange(of: viewModel.isDelete) { isDelete in
            if isDelete {
                dismiss()
            }
        }
        .onChange(of: viewModel.members) { _ in
                //멤버 나갈시 뷰 재생성
        }
    }
}






