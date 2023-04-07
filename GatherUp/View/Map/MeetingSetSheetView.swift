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
    @State var description: String
    var onDismiss: (() -> Void)?
    @State private var showError = false
    @Binding var coordinateCreated: CLLocationCoordinate2D
    @StateObject private var viewModel:MapViewModel2 = .init()
  
    
    
    
    
    init(coordinateCreated: Binding<CLLocationCoordinate2D>,onDismiss: (() -> Void)? = nil) {
        _title = State(initialValue: "")
        _description = State(initialValue: "")
        _coordinateCreated = coordinateCreated
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(alignment: .center){
                    Spacer()
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
                    Spacer()
                    Button{
                        if( title.isEmpty || description.isEmpty){
                            showErrorMessage(duration: 2)
                        }
                        else{
                            
                            var user = Auth.auth().currentUser
                            presentationMode.wrappedValue.dismiss()
                            onDismiss?()
                            let newMeeting = Meeting(title: title, description: description, latitude:  coordinateCreated.latitude,longitude: coordinateCreated.longitude,userName: (user?.displayName!)!,userUID: user!.uid,userImage: user?.photoURL!)
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
    
    
/*
struct MeetingSetSheetView_Previews: PreviewProvider {
        static var previews: some View {
            MeetingSetSheetView()
        }
}*/


struct PopupError: View {
    var body: some View {
        Text("빈칸을 모두 채워주세요!")
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.8))
            .cornerRadius(10)
    }
}

