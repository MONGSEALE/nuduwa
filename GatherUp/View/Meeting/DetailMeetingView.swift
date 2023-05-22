//
//  DetailMeetingView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/04.
//

import SwiftUI
import SDWebImageSwiftUI

struct DetailMeetingView: View {
     @StateObject var viewModel: MeetingViewModel = .init()

    // var meeting: Meeting
    let meetingID: String
    let hostUID: String
    // @Environment(\.dismiss) private var dismiss
    
    @State private var isEdit: Bool = false
    @State private var editTitle: String? = nil
    @State private var editDescription: String? = nil
    @State private var editPlace: String? = nil
    @State private var editNumbersOfMembers: Int? = nil
    @State private var editMeetingDate: Date? = nil
    
    @State private var toChatView: Bool = false
 
    
    /// 시간 설정 제한 범위
    var dateRange: ClosedRange<Date>{
        let min = Calendar.current.date(byAdding: .minute, value: 0, to: viewModel.meeting?.publishedDate ?? Date())!
        let max = Calendar.current.date(byAdding: .day, value: 6, to: viewModel.meeting?.publishedDate ?? Date())!
        
        return min...max
    }
  
    var body: some View {
        let isHost = hostUID == viewModel.currentUID
        let meeting = viewModel.meeting ?? Meeting.updateMeeting()  //nil이면 텅빈 모임

        NavigationStack{
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top,30)
            }else{
                ScrollView(.vertical, showsIndicators: false){
                    LazyVStack(spacing:30){
                        HStack(spacing: 12){
                            WebImage(url: viewModel.user?.userImage ?? meeting.hostImage).placeholder{ProgressView()}
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                            
                            
                            VStack(alignment: .leading, spacing: 6){
                                Text(viewModel.user?.userName ?? meeting.hostName ?? "")
                                    .font(.callout)
                                Text("\(meeting.meetingDate.formatted(date: .numeric, time: .shortened))에 생성됨")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .hAlign(.leading)
                        }
                        EditTextMeeting(text: meeting.title, editText: $editTitle, item: "모임 제목",isEditable: isEdit)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        EditTextMeeting(text: meeting.description, editText: $editDescription, item: "모임 내용", isEditable: isEdit)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        EditTextMeeting(text: meeting.place , editText: $editPlace , item:"모임 장소",isEditable: isEdit)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        EditDatePicker(date: meeting.meetingDate, editDate: $editMeetingDate, item:"모임 시간",isEditable:isEdit, range: dateRange)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        
                        
                        VStack {
                            Text("참여자")
                                .font(.caption2)
                            HStack{
                                ForEach(Array(viewModel.dicMembers.values)){ member in
                                    MemberImageButton(member: member, isCurrent: member.memberUID == viewModel.currentUID)
                                }
                            }
                                .frame(maxWidth: 340 , alignment: .center)
                        }
                        .padding(.horizontal,5)
                        .padding(.vertical,20)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        
                        Button{
                            toChatView = true
                        } label: {
                            Text("채팅 참가")
                                .font(.callout)
                                .foregroundColor(.white)
                                .padding(.horizontal,150)
                                .padding(.vertical,10)
                                .background(.blue,in: RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.top, -10)
                        .fullScreenCover(isPresented: $toChatView) {
                            NavigationView {
                                ChatView(meetingID: meeting.id!, meetingTitle: meeting.title, hostUID: meeting.hostUID, members: $viewModel.dicMembers)
                            }
                        }


                    }
                }
                .padding(10)
                
             
                
                
                /// Host 여부에 따라 버튼 보이기
              
            }
            
        }
        .toolbar {
            
            ToolbarItem(placement: .navigationBarLeading) {
                   if isEdit {
                       Button{
                           isEdit.toggle()
                       } label :{
                           Image(systemName: "chevron.left")
                           Text("수정 취소")
                       }
                   } else {
                       // 기존에 있던 내용 (예: "<내모임"으로 되돌아가는 버튼)
                   }
               }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if(isEdit==false){
                            Menu {
                                Group{
                                    if isHost{
                                        Button("모임 수정", action: {
                                            isEdit.toggle()
                                        })
                                        Button("모임 삭제", role: .destructive, action: {
                                            viewModel.deleteMeeting(meetingID: meeting.id!)
                                            dismiss()
                                            
                                        })
                                    }
                                    else{
                                        Button("모임 나가기", action: {
                                            viewModel.leaveMeeting(meetingID: meeting.id!, memberUID: viewModel.currentUID)
                                            dismiss()
                                        })
                                    }
                                }
                                
                                
                            } label: {
                                Image(systemName: "list.bullet")
                            }
                        }
                        else{
                            Button{
                                if viewModel.meeting != nil{
                                                   viewModel.editMeeting(title: editTitle, description: editDescription, place: editPlace, numbersOfMembers: editNumbersOfMembers, meetingDate: editMeetingDate)
                                }
                                               isEdit.toggle()
                            } label: {
                                Text("수정 완료")
                            }
                        }
                    }
                }
        .navigationBarBackButtonHidden(isEdit)
        .onAppear{
            viewModel.fetchUser(hostUID)
            viewModel.meetingListener(meetingID: meetingID)
            viewModel.membersListener(meetingID: meetingID)
        }
//        .onDisappear{
//            viewModel.removeListeners()
//        }
    }
}

struct EditTextMeeting: View {
    let text: String
    @Binding var editText: String?
    let item: String
    let isEditable: Bool
    
    var body: some View {
      if isEditable {
          TextField(item, text: Binding<String>(
                            get: { self.editText ?? ""
                            },
                            set: { self.editText = $0.isEmpty ? nil : $0 }
                        ))
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .padding()
              .onAppear{
                  editText = text
              }
              .onDisappear{
                if editText == text{
                    editText = nil
                }
              }
      } else {
          if (item == "모임 내용"){
              HStack(alignment: .top){
                      Image(systemName: "highlighter")
                      Text(text)
                          .font(.body)
              }
              .padding(.vertical,6)
          }
          else if(item == "모임 장소"){
              HStack(alignment: .top){
                      Image(systemName: "mappin.and.ellipse")
                  Text(text)
                      .font(.body)
              }
              .padding(.vertical,6)
          }
          else{
              Text("    \(text)")
                  .font(.title)
                  .fontWeight(.bold)
                  .padding(.vertical,6)
          }
      }
    }
}

struct EditDatePicker: View {
    let date: Date
    @Binding var editDate: Date?
    let item: String
    let isEditable: Bool
    let range: ClosedRange<Date>?

    var body: some View {
        if isEditable {
            DatePicker(item, selection: Binding<Date>(
                get: { self.editDate ?? self.date },
                set: { self.editDate = $0 }
            ), in: range ?? Date()...Date().addingTimeInterval(60*60*24*365))
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .onAppear{
                    editDate = date
                }
                .onDisappear{
                    if editDate == date{
                        editDate = nil
                    }
                }
        } else {
            HStack(alignment: .top){
                    Image(systemName: "calendar")
                
                Text("\(date, format: .dateTime.month().day().hour().minute())에 만나요!")
                    .font(.body)
            }
            .padding(.vertical,6)
        }
    }
}



struct MemberImageButton: View {
    let member: Member
    let isCurrent: Bool
    @State var showProfile: Bool = false
    
    var body: some View {
        Button{
            showProfile = true
        } label: {
            WebImage(url: member.memberImage).placeholder{ProgressView()}
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .sheet(isPresented: $showProfile){
                    MemberProfileView(member: member, isCurrent: isCurrent)
                }
        }
    }
}






