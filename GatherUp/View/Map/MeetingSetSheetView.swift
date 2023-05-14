//
//  MeetingSetSheetView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/04.
//

import SwiftUI
import CoreLocation


struct MeetingSetSheetView: View {
    
    /// Meeting 저장용
    @State private var title:String = ""
    @State private var description: String = ""
    @State private var place: String = ""
    @State private var selection : Int = 0
    @State private var meetingDate = Date()
    let coordinateCreated: CLLocationCoordinate2D
    
    let onCreate: (Meeting)->()
    
    @State private var showError = false
    @State private var showPlacePopUp = false
    @State private var noMorePlacePopUp = false
   
    let currentdate = Date()
    
    /// 시간 설정 제한 범위
    var dateRange: ClosedRange<Date>{
        let min = Calendar.current.date(byAdding: .minute, value: 0, to: currentdate)!
        let max = Calendar.current.date(byAdding: .day, value: 6, to: currentdate)!
        
        return min...max
    }

    var closedRange = Calendar.current.date(byAdding: .year, value: -1,to:Date())
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .center){
                    Spacer()
                    Form{
                        Section(header:Text("모임정보")){
                            TextField("모임제목",text: $title)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                            
                                .padding(.horizontal)
                                .foregroundColor(.black)
                                .accentColor(.blue)
                            TextField("모임설명",text: $description)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .padding(.horizontal)
                                .foregroundColor(.black)
                                .accentColor(.blue)
                        }
                        Section(header:Text("장소")){
                            TextField("모임위치",text: $place)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1)
                                )
                                .onTapGesture {
                                    if noMorePlacePopUp == false{
                                        showPlacePopUp = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        showPlacePopUp = false
                                        noMorePlacePopUp = true
                                    }
                                }
                        }
                        Section(header:Text("시간 설정")){
                            DatePicker("",selection: $meetingDate, in:dateRange)
                                .datePickerStyle(GraphicalDatePickerStyle())
                                
                        }
                        
                        Section(header:Text("최대 인원수")){
                            Picker(
                                selection: $selection,
                                label:HStack{
                                    Text("인원수:")
                                    Text("\((selection)+2)")
                                }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .padding(.horizontal)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .shadow(color: Color.blue.opacity (0.3),
                                     radius: 10, x: 0, y: 10),
                                content: {
                                    ForEach(2..<11) { number in
                                        Text("\(number)")
                                            .tag("\(number)")
                                    }
                                }
                            )
                        }
                    }
                    Spacer()
                    Button{
                        if( title.isEmpty || description.isEmpty || place.isEmpty){
                            showErrorMessage(duration: 2)
                        }
                        else{
                            let newMeeting = Meeting.createNewMeeting(title: title, description: description, place: place, numbersOfMembers: selection+2, location: coordinateCreated, meetingDate: meetingDate)
                            
                            // Meeting(title: title, description: description, place:place, numbersOfMembers:selection+2, latitude:coordinateCreated.latitude, longitude: coordinateCreated.longitude, geoHash: "", meetingDate:meetingDate, hostUID: "")
                            onCreate(newMeeting)
                        }
                    }label: {
                        Text("확인")
                    }
                }
                if(showError==true){
                    PopupError()
                }
                if showPlacePopUp {
                    VStack(spacing: 0) {
                                     Text("장소를 상세히 입력해주세요!")
                                         .foregroundColor(.white)
                                         .padding(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                                         .background(Color.black.opacity(0.8))
                                         .cornerRadius(8)
                        
                        
                                     Rectangle()
                                         .fill(Color.black.opacity(0.8))
                                         .frame(width: 12, height: 12)
                                         .rotationEffect(.degrees(45))
                                         .offset(x: 20, y: -6)
                                 }
                                 .offset(y: -110)
                                 .animation(.easeInOut(duration: 0.2))
                            }
            }
            .navigationBarTitle("")
            .navigationBarItems(
                leading: Button(action: {
//                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Image(systemName: "arrow.left")
                })
            )
        }
    }
    
    func showErrorMessage(duration: TimeInterval) {
        // Show the message
        withAnimation {
            showError = true
        }

        // Hide the message after the specified duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                showError = false
            }
        }
    }
}

struct PopupError: View {
    var body: some View {
        Text("빈칸을 모두 채워주세요!")
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
    }
}
