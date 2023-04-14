//
//  MeetingSetSheetView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/04/04.
//

import SwiftUI
import CoreLocation
import Firebase


struct MeetingSetSheetView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @State private var title:String
    @State private var description: String
    @State private var place: String
    @State private var members: Int
    var onDismiss: (() -> Void)?
    @State private var showError = false
    @State private var showPlacePopUp = false
    @State private var noMorePlacePopUp = false
    @Binding var coordinateCreated: CLLocationCoordinate2D
    @StateObject private var viewModel:MapViewModel2 = .init()
    @State private var meetingTime = Date()
    @State private var selection : Int
    
    
   

    
    
    var closedRange = Calendar.current.date(byAdding: .year, value: -1,to:Date())
    
    
    
    
    init(coordinateCreated: Binding<CLLocationCoordinate2D>,onDismiss: (() -> Void)? = nil) {
        _title = State(initialValue: "")
        _description = State(initialValue: "")
        _place = State(initialValue: "")
        _members = State(initialValue: 0)
        _selection = State(initialValue: 0)
        _coordinateCreated = coordinateCreated
        self.onDismiss = onDismiss
    }
    
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
                            DatePicker("모임 시간을 정해주세요:",selection: $meetingTime,displayedComponents: .hourAndMinute)
                        }
                        
                        Section(header:Text("인원수")){
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
                            var user = Auth.auth().currentUser
                            presentationMode.wrappedValue.dismiss()
                            onDismiss?()
                            
                            let currentDate = Date()
                           
                            let newMeeting = Meeting(title: title, description: description, place:place,numbersOfMembers:selection+1,latitude:  coordinateCreated.latitude,longitude: coordinateCreated.longitude,publishedDate:currentDate, meetingDate:meetingTime, hostName: (user?.displayName!)!,hostUID: user!.uid,hostImage: user?.photoURL!)
                            viewModel.createMeeting(meeting: newMeeting)
                            print(newMeeting)
                            
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
                    presentationMode.wrappedValue.dismiss()
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
    
    

struct MeetingSetSheetView_Previews: PreviewProvider {
    
    @State static var coordinateCreated = CLLocationCoordinate2D()
        static var previews: some View {
            MeetingSetSheetView(coordinateCreated: $coordinateCreated)
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
