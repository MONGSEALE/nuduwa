//
//  DetailMeetingView.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/04/04.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase

struct DetailMeetingView: View {
    @StateObject var viewModel: MeetingViewModel = .init()
    
    @State var meeting: Meeting
    @Environment(\.dismiss) private var dismiss
    @State var isEdit: Bool = false
    @State private var title: String = ""
    @State private var description: String = ""
    @State var meetingDate: Date
    
    @State private var toChatView: Bool = false
    
    /// 시간 설정 제한 범위
    var dateRange: ClosedRange<Date>{
        let min = Calendar.current.date(byAdding: .minute, value: 0, to: meeting.meetingDate)!
        let max = Calendar.current.date(byAdding: .day, value: 6, to: meeting.meetingDate)!
        
        return min...max
    }

  
    var body: some View {
        let isHost = meeting.hostUID == Auth.auth().currentUser?.uid ? true : false
        
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack{
                HStack(spacing: 12){
                    WebImage(url: meeting.hostImage).placeholder{
                        // MARK: Placeholder Image
                        Image("NullProfile")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6){
                        CustomText(text: meeting.title, editText: $title, item: "모임 제목",isEditable: isEdit)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(meeting.hostName)
                            .font(.callout)
                        Text(meeting.publishedDate.formatted(date: .numeric, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .hAlign(.leading)
                }
                CustomText(text: meeting.description, editText: $description, item: "모임 내용", isEditable: isEdit)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                    .hAlign(.leading)
                if isHost && isEdit {
                    Section(header:Text("시간 설정")){
                        DatePicker("",selection: $meetingDate, in:dateRange)
                            .datePickerStyle(GraphicalDatePickerStyle())
                    }
                }
                HStack{
                    Text("참여자:")
                    ForEach(viewModel.members){ member in
                        Text(" \(member.memberName),")
                    }
                }
                
             //
            }
            .onAppear{
                viewModel.membersListener(meetingId: meeting.id!)
                print("맴버수:\(viewModel.members.count)")
            }
            .padding(15)
        }
        
        
        Button{
            toChatView = true
        } label: {
            Text("채팅 참가")
                .font(.callout)
                .foregroundColor(.white)
                .padding(.horizontal,30)
                .padding(.vertical,10)
                .background(.blue,in: Capsule())
        }
        .sheet(isPresented: $toChatView){
            ChatView(meetingID:meeting.id!,hostUID: meeting.hostUID, members: $viewModel.members,meetingTitle: meeting.title)
        }
         
        HStack{
            if isHost {
                if isEdit{
                    Button(action: {
                        guard title != "" else {
                            print("title없음")
                            return
                        }
                        guard description != "" else {
                            print("내용없음")
                            return
                        }
                        viewModel.updateMeeting(editMeeting: meeting, title: title, description: description, meetingDate: meetingDate)
                        meeting.title = title
                        meeting.description = description
                        isEdit.toggle()
                    }){
                        Text("수정 완료")
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(.horizontal,30)
                            .padding(.vertical,10)
                            .background(.blue,in: Capsule())
                    }
                    Button(action: {
                        title = meeting.title
                        description = meeting.description
                        isEdit.toggle()
                    }){
                        Text("수정 취소")
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(.horizontal,30)
                            .padding(.vertical,10)
                            .background(.red,in: Capsule())
                    }
                } else {
                    Button(action: {
                        isEdit.toggle()
                    }){
                        Text("모임 수정")
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(.horizontal,30)
                            .padding(.vertical,10)
                            .background(.blue,in: Capsule())
                    }
                    Button(action: {
                        viewModel.deleteMeeting(deletedMeeting: meeting)
                        dismiss()
                    }){
                        Text("모임 삭제")
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(.horizontal,30)
                            .padding(.vertical,10)
                            .background(.red,in: Capsule())
                    }
                }
                
            } else {
                Button(action: {
                    viewModel.leaveMeeting(meetingId: meeting.id!)
                    dismiss()
                }){
                    Text("모임 나가기")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal,30)
                        .padding(.vertical,10)
                        .background(.red,in: Capsule())
                }
            }
        }
        .padding(10)
    }
}

struct CustomText: View {
    let text: String
    @Binding var editText: String
    let item: String
    let isEditable: Bool
    
    var body: some View {
      if isEditable {
          TextField(item, text: $editText)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .padding()
              .onAppear{
                  editText = text
              }
      } else {
          Text(text)
              .font(.title)
              .fontWeight(.bold)
              .padding()
      }
    }
}


