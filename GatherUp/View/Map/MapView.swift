//
//  MapView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//



import SwiftUI
import MapKit
import CoreLocationUI
import Firebase

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State var showAnnotation = false
    @State private var coordinate = CLLocationManager()
    
    @State private var showMessage = false
    @State private var showCreateMessage = false
    @State private var showSheet = false
    @State private var showCreateConfirmedMessage = false
    
    @State private var coordinateCreated = CLLocationCoordinate2D()
    
    
    @StateObject private var serverViewModel: FirebaseViewModel = .init()   /// Firebase 연결 viewmodel
    let user = Auth.auth().currentUser                                      /// 현재 로그인 중인 유저정보 변수
    @State var message: String = ""
    
    @State var locate: CLLocationCoordinate2D?
    
    var body: some View {
        ZStack(alignment:.bottom){
            GeometryReader { geometry in
                /// serverViewModel의 meetings 배열에서 item(meeting) 하나씩 가져와서 지도에 Pin 표시
                Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: serverViewModel.meetings){ item in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude), content: {
                        /// 지도에 표시되는 MapPin중 모임 생성중인 Pin이면 if문 View 아니면 else문 View
                        if(serverViewModel.isOverlap==false && user?.uid == item.hostUID){
                            CustomMapAnnotationView()
                            
                        }else{
                            MeetingIconView(meeting: item) { locate in
                                withAnimation(.easeInOut(duration: 0.25)){
                                    viewModel.region.center = locate
                                    self.locate = locate
                                }
                            }
                        }
                    })
                }
                .edgesIgnoringSafeArea(.top)
                .accentColor(Color(.systemPink))
                .onAppear{
                    guard let user = user else{return}             /// 혹시라도 로그인한 유저 정보 없으면 return
                    serverViewModel.meetingsListner()              /// Map이 보여지는동안 Firebase와 실시간 연동
                    serverViewModel.checkedOverlap(id: user.uid)   /// Map이 보여지는동안 실시간 중복확인
                    viewModel.checkIfLocationServicesIsEnabled()
                }
                .onDisappear{
                    serverViewModel.removeListner()                /// Map을 안보면 실시간 연동 중단
                }
                .onTapGesture { tapLocation in
                    if(showAnnotation==true){
                        
                        let tapCoordinate = coordinateFromTap(tapLocation, in: geometry, region: viewModel.region)
                               let userLocation = CLLocation(latitude: viewModel.region.center.latitude, longitude: viewModel.region.center.longitude)
                               let tappedLocation = CLLocation(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude)
                               let distanceInMeters = userLocation.distance(from: tappedLocation)

                               if distanceInMeters <= 3000 {
                                   let newMeeting = Meeting(title: "", description: "", place: "", numbersOfMembers: 0, latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude, hostName: user!.displayName!, hostUID: user!.uid, hostImage: user!.photoURL)
                                   
                                   serverViewModel.addMeeting(newMeeting: newMeeting)
                                   coordinateCreated = CLLocationCoordinate2D(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude)
                               } else {
                                   showPopupMessage(message: "모임의 거리가 너무 멀어요!", duration: 3)
                               }
                
                    }
                }
                /*
                 .overlay(GeometryReader { geometry in
                 if(showAnnotation==true){
                 Color.clear
                 .contentShape(Rectangle())
                 .gesture(DragGesture(minimumDistance: 0)
                 .onChanged { gesture in
                 // Calculate the translation in points
                 self.viewModel.region.center.latitude += Double(gesture.translation.height) / Double(geometry.size.height) * self.viewModel.region.span.latitudeDelta
                 self.viewModel.region.center.longitude -= Double(gesture.translation.width) / Double(geometry.size.width) * self.viewModel.region.span.longitudeDelta
                 }
                 .onEnded({ value in
                 let tapLocation = value.location
                 let tapCoordinate = coordinateFromTap(tapLocation, in: geometry, region: viewModel.region)
                 /// 지도에 위치표시하기 위한 임시 Meeting데이터
                 let newMeeting = Meeting(title: "", description: "", place: "", numbersOfMembers: 0, latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude, hostName: user!.displayName!, hostUID: user!.uid, hostImage: user!.photoURL)
                 
                 serverViewModel.addMeeting(newMeeting: newMeeting)
                 coordinateCreated=tapCoordinate
                 })
                 )
                 }
                 })
                 */
            }
            VStack{
                HStack{
                    Spacer()
                    Button{
                        /// 모임 중복 생성이면 if문 실행
                        if (serverViewModel.isOverlap==true){
                            showPopupMessage(message: "모임은 최대 한개만 생성할 수 있습니다!", duration: 2)
                        }else{
                            /// 모임만들기 버튼 클릭할때마다 if문과 else문 번갈아 실행
                            if(showAnnotation==false){
                                /// 모임만들기 버튼 클릭하면 "장소를 선택해주세요!" 메시지 출력
                                showPopupMessage(message: "장소를 선택해주세요!", duration: 2)
                                withAnimation(.spring()){
                                    showAnnotation.toggle()
                                }
                            }else{
                                withAnimation(.spring()){
                                    showAnnotation.toggle()
                                }
                                serverViewModel.cancleMeeting()     /// 취소 버튼 누르면 MapPin 삭제
                            }
                        }
                    }label: {
                        Group {
                            if showAnnotation {
                                //CustomCancleView()
                            } else {
                                Text("모임만들기")
                                    .fontWeight(.bold)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color.white)
                                    .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                                    .background(Color.blue) // Moved the background modifier inside the else block
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(15)
                    
                   
                }
                Spacer()
               
                HStack{
                    Spacer()
                    Button {
                        viewModel.requestAllowOnceLocationPermission()
                    } label:{
                        Image(systemName:"location.north.fill")
                            .resizable()
                            .frame(width: 30,height: 30)
                            .foregroundColor(.white)
                            .padding(15)
                            .background(.blue)
                            .clipShape(Circle())
                    }
                    Spacer().frame(width: 20)
                }
                Spacer().frame(height: showAnnotation ? 0 : 35 )
                
                
                    if(showAnnotation==true){
                        Button{
                            /// 새로 생성할 모임 위치를 클릭 안하면 if문 실행해서 메시지 띄우기
                            if(serverViewModel.newMeeting == nil){
                                showPopupMessage(message: "장소를 반드시 선택해주세요!", duration: 3)
                            }
                            else{
                                showSheet=true
                            }
                        }label: {
                            Text("생성하기!")
                        }
                        .background(Color.white)
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(width: 90, height: 35)
                        .buttonStyle(.borderedProminent)
                        .sheet(isPresented: $showSheet){
                            MeetingSetSheetView(coordinateCreated: $coordinateCreated, onDismiss: {
                                /// 모임 생성 완료되면 실행
                                showAnnotation = false
                                serverViewModel.newMeeting = nil
                                serverViewModel.isOverlap = true
                            })
                            .environmentObject(viewModel)
                        }
                    }
                    
                
                
                
            }
            if showMessage{
                ShowMessage(message: message)
            }
        }
    }
    
    func showPopupMessage(message: String, duration: TimeInterval) {
        // Show the message
        withAnimation {
            self.message = message
            showMessage = true
        }
        // Hide the message after the specified duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                showMessage = false
                self.message = ""
            }
        }
    }
    
    func coordinateFromTap(_ tapLocation: CGPoint, in geometry: GeometryProxy, region: MKCoordinateRegion) -> CLLocationCoordinate2D {
        if serverViewModel.newMeeting != nil {
            // Remove the previous annotation from the map
            serverViewModel.cancleMeeting()
            viewModel.objectWillChange.send()
        }
        let frame = geometry.frame(in: .local)
        let x = Double(tapLocation.x / frame.width) * region.span.longitudeDelta + region.center.longitude - region.span.longitudeDelta / 2
        let y = Double((frame.height - tapLocation.y) / frame.height) * region.span.latitudeDelta + region.center.latitude - region.span.latitudeDelta / 2
        return CLLocationCoordinate2D(latitude: y, longitude: x)
    }
}
        
    



struct ShowMessage: View {
    let message: String
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(message)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                Spacer()
            }
            Spacer()
        }
        .transition(.scale)
    }
}

class MapViewModel : NSObject, ObservableObject,CLLocationManagerDelegate{

    
    @Published var region = MKCoordinateRegion(center:CLLocationCoordinate2D(latitude: 37.5665, longitude:126.9780 ),
                                                   span:MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    

    var locationManager : CLLocationManager?
    
    override init() {
        super.init()
        locationManager?.delegate=self
    }
    
    func requestAllowOnceLocationPermission(){
        locationManager?.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:
    [CLLocation]) {
        guard let latestLocation = locations.first else{
            return
        }
        
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(center:latestLocation.coordinate,span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func checkIfLocationServicesIsEnabled(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager = CLLocationManager()
            checkLocationAuthorization()
            locationManager!.delegate=self
        }
        else{
            print("permission denied")
        }
    }
    
    func checkLocationAuthorization(){
        guard let locationManager = locationManager else {return}
        
        switch locationManager.authorizationStatus{
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("Your location is restricted likely due to parental controls ")
        case .denied:
            print("You have denied this app location permission. Go into settings to change it")
        case .authorizedAlways, .authorizedWhenInUse:
            region = MKCoordinateRegion(center:locationManager.location!.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
   
    
    func centerMapOn(_ coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            self.region = MKCoordinateRegion(center: coordinate, span: self.region.span)
        }
    }
}


extension MKCoordinateRegion {
    var zoomLevel: Int {
        let maxZoomLevel = 20
        let zoomLevel = Int(log2(360 * Double(UIScreen.main.bounds.width) / (256 * self.span.longitudeDelta))) + 1
        return min(maxZoomLevel, max(1, zoomLevel))
    }
}

