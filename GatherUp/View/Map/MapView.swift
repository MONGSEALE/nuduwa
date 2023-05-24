//
//  MapView.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//



import SwiftUI
import MapKit
import CoreLocationUI
import Dispatch

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var serverViewModel: MapViewModel2 = .init()   /// Firebase 연결 viewmodel
    
    @State private var showAnnotation = false             /// 모임 생성시 지도에 핀 표시
    @State private var coordinate = CLLocationManager()   ///
    
    @State private var showMessage = false    /// 중복생성등 알람 메시지
    @State private var message: String = ""    /// 중복생성등 알람 메시지 내용
    @State private var showSheet = false    /// 모임 제목, 내용 등 입력할 시트 띄우기
    
    @State private var coordinateCreated = CLLocationCoordinate2D()
    
    var body: some View {
        ZStack(alignment:.bottom){
            GeometryReader { geometry in
                /// serverViewModel의 meetings 배열에서 item(=meeting) 하나씩 가져와서 지도에 Pin 표시
                Map(coordinateRegion: $viewModel.region, showsUserLocation: true, annotationItems: serverViewModel.meetings){ item in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude), content: {
                        /// 지도에 표시되는 MapPin중 모임 생성중인 Pin이면 if문 View 아니면 else문 View
                        switch item.type {
                        case .basic:
                            MeetingIconView(showAnnotation: $showAnnotation, isJoin: serverViewModel.meetingsList.contains(where: { $0.meetingID == item.id! }), meeting: item) { locate in
                                withAnimation(.easeInOut(duration: 0.25)){
                                    viewModel.region.center = locate
                                }
                            }
                        case .piled:
                            if let meetings = serverViewModel.bigIconMeetings[item.id!] {
                                PiledMeetingIconView(showAnnotation: $showAnnotation, meetings: meetings, isJoinIDs: serverViewModel.meetingsList.map{ $0.meetingID }) { locate in
                                    withAnimation(.easeInOut(duration: 0.25)){
                                        viewModel.region.center = locate
                                    }
                                }
                            }
                        case .new:
                            CustomMapAnnotationView()
                        }
                    })
                }
                .edgesIgnoringSafeArea(.top)
                .accentColor(Color(.systemPink))
                .onChange(of: viewModel.region) { region in
//                    viewModel.region = viewModel.region.clampedLongitudeDelta(minValue: 0.01, maxValue: 0.1)
                    serverViewModel.checkedLocation(region: region)
                }
                .onAppear{
                    serverViewModel.mapMeetingsListener(region: viewModel.region)              /// Map이 보여지는동안 Firebase와 실시간 연동
                    viewModel.checkIfLocationServicesIsEnabled()
                    serverViewModel.meetingsListListener()
                }
                .onTapGesture { tapLocation in
                    if(showAnnotation==true){
                        let tapCoordinate = coordinateFromTap(tapLocation, in: geometry, region: viewModel.region)
                        let userLocation = CLLocation(latitude: viewModel.region.center.latitude, longitude: viewModel.region.center.longitude)
                        let tappedLocation = CLLocation(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude)
                        let distanceInMeters = userLocation.distance(from: tappedLocation)

                        if distanceInMeters <= 3000 {
                           coordinateCreated = CLLocationCoordinate2D(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude)
                           serverViewModel.addMapAnnotation(newMapAnnotation: coordinateCreated)
                        } else {
                           showPopupMessage(message: "모임의 거리가 너무 멀어요!", duration: 3)
                        }
                    }
                }
            }  //GeometryReader끝

            VStack{
                HStack{
                    Menu {
                        ForEach(Meeting.Category.allCases, id: \.self) { item in
                            // Meeting 구조체 Category에 있는 모든 케이스 반복
                            Button{
                                if serverViewModel.category != item {
                                    serverViewModel.filterMeetingsByCategory(category: item, latitudeDelta: viewModel.region.span.latitudeDelta)
                                } else {
                                    serverViewModel.filterMeetingsByCategory(category: nil, latitudeDelta: viewModel.region.span.latitudeDelta)
                                }
                            } label: {
                                // 선택하면 serverViewModel.category?.rawValue ?? "")==item.rawValue 가 true
                                Label(item.rawValue, systemImage: (serverViewModel.category?.rawValue ?? "")==item.rawValue ?  "pencil" : "")
                            }

                        }
                    } label: {
                        Text(serverViewModel.category?.rawValue ?? "필터")
                            .fontWeight(.bold)
                            .font(.system(size: 20))
                            .foregroundColor(Color.white)
                            .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                            .background(Color.yellow) // Moved the background modifier inside the else block
                            .cornerRadius(20)
                    }
                    .padding(15)
                    Spacer()
                    Button{
//test 중 비활성화                        /// 모임 중복 생성이면 if문 실행
//test 중 비활성화                        if (serverViewModel.isOverlap==true){
//test 중 비활성화                            showPopupMessage(message: "모임은 최대 한개만 생성할 수 있습니다!", duration: 2)
//test 중 비활성화                        }else{
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
                                serverViewModel.deleteMapAnnotation()     /// 취소 버튼 누르면 MapPin 삭제
                            }
//test 중 비활성화                        }
                    }label: {
                        Group {
                            if showAnnotation {
                                CustomCancleView()
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
                            MeetingSetSheetView(coordinateCreated:coordinateCreated) { newMeeting in
                                serverViewModel.createMeeting(meeting: newMeeting)
                                showAnnotation = false
                                serverViewModel.newMeeting = nil
                                serverViewModel.isOverlap = true
                            }
                        }
                    }
            }
            if showMessage{
                ShowMessage(message: message)
            }
        }
        .overlay(content: {
            LoadingView(show: $serverViewModel.isLoading)
        })
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
            serverViewModel.deleteMapAnnotation()
            viewModel.objectWillChange.send()
        }
        let frame = geometry.frame(in: .local)
        let x = Double(tapLocation.x / frame.width) * region.span.longitudeDelta + region.center.longitude - region.span.longitudeDelta / 2
        let y = Double((frame.height - tapLocation.y) / frame.height) * region.span.latitudeDelta + region.center.latitude - region.span.latitudeDelta / 2
        print("tap:\(tapLocation)")
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

    @Published var region = MKCoordinateRegion(center:CLLocationCoordinate2D(latitude: 37.5665, longitude:126.9780 ), span:MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    
    var locationManager : CLLocationManager?
    
    override init() {
        super.init()
        locationManager?.delegate=self
    }
    
    func requestAllowOnceLocationPermission(){
        print("6")
        locationManager?.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:
    [CLLocation]) {
        print("5")
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
        print("2")
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
        print("3")
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
        if region.span.longitudeDelta > 1 {return}
        print("1")
        print("longitudeDelta:\(region.span.longitudeDelta)")
        checkLocationAuthorization()
    }
    
    func centerMapOn(_ coordinate: CLLocationCoordinate2D) {
        print("4")
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

/// MKCoordinateRegion 타입을 .onChange에서 사용가능하게 확장하는 코드. 현재 필요없어서 주석처리
extension MKCoordinateRegion: Equatable {
   public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
       return lhs.center.latitude == rhs.center.latitude &&
              lhs.center.longitude == rhs.center.longitude &&
              lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
              lhs.span.longitudeDelta == rhs.span.longitudeDelta
   }
}

extension MKCoordinateRegion {
    func clampedLongitudeDelta(minValue: CLLocationDegrees, maxValue: CLLocationDegrees) -> MKCoordinateRegion {
        var clampedSpan = span
        
        if clampedSpan.longitudeDelta < minValue {
            clampedSpan.longitudeDelta = minValue
        } else if clampedSpan.longitudeDelta > maxValue {
            clampedSpan.longitudeDelta = maxValue
        }
        
        return MKCoordinateRegion(center: center, span: clampedSpan)
    }
}
