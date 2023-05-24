//
//  ReusableProfileContent.swift
//  Nudowa
//
//  Created by DaelimCI00007 on 2023/03/28.
//

import SwiftUI
import SDWebImageSwiftUI
import PhotosUI

struct ReusableProfileContent: View {
    @State var photoItem: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    @State var showImagePicker: Bool = false
    @State var isBool = true
    @State var editName: String?
    @State var isEdit: Bool = false
    @State private var progress: CGFloat = 0.7
    

//    var onEdit: (String?, PhotosPickerItem?)->()
    @StateObject var viewModel: ProfileViewModel = .init()
    
    @State var showPopup : Bool = false
    @State var errorMessage: String = ""
    

    var body: some View {
        NavigationStack{
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(){
                    HStack(spacing:0){
                        ZStack{
                            if isEdit, let imageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 50,height: 50)
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                                    .padding(.leading, -20)
                            }else{
                                WebImage(url: user.userImage).placeholder{ProgressView()}
                                    .resizable()
                                    .frame(width: 50,height: 50)
                                    .aspectRatio(contentMode: .fill)
                                    .clipShape(Circle())
                                    .padding(.leading, -20)
                            }
                                
                                if isEdit {
                                    Image(systemName: "square.and.arrow.down")
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .onTapGesture{
                                if isEdit {
                                    showImagePicker.toggle()
                                }
                            }
                            .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
                            .onChange(of: photoItem) { newItem in
                                Task {
                                    // Retrive selected asset in the form of Data
                                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                        imageData = data
                                    }
                                }
                            }
                            
                            EditTextProfile(text: viewModel.user?.userName ?? "" , editText: $editName, item: "닉네임", isEditable: isEdit)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.leading, -20)
                            Spacer()
                        }
                        .padding(.bottom,20)
                        
                        GaugeView(progress: $progress)
                            .frame(width: 200, height: 200)
                        Slider(value: $progress)
                        
                        Divider()
                        HStack{
                            VStack{
                                Text("87")
                                    .font(.title)
                                    .font(.system(size:17))
                                    .fontWeight(.bold)
                                Text("만든 모임")
                                    .font(.system(size:15))
                                    .fontWeight(.light)
                                    .foregroundColor(.gray)
                            }
                            VStack{
                                Text("15")
                                    .font(.title)
                                    .font(.system(size:17))
                                    .fontWeight(.bold)
                                Text("리뷰")
                                    .font(.system(size:15))
                                    .fontWeight(.light)
                                    .foregroundColor(.gray)
                            }
                            VStack{
                                
                            }
                        }
                        Divider()
                        HStack{
                            Spacer()
                                .frame(width: 15)
                            Text("자기소개")
                                .font(.body)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        EditTextProfile(text: "자기소개입니당" , editText: $editName, item: "자기소개", isEditable: isEdit)
                            .font(.body)
                            .fontWeight(.thin)
                        //   .hAlign(.leading)
                        
                        HStack{
                            Spacer()
                                .frame(width: 15)
                            Text("흥미")
                                .font(.body)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        EditInterestProfile(isEditable: isEdit){errorText in
                            errorMessage = errorText
                            withAnimation(.easeInOut){
                                  showPopup = true
                              }
                              
                              DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                  withAnimation(.easeInOut){
                                      showPopup = false
                                  }
                              }
                        }
                    }
                    .padding(15)
                }
                .navigationTitle("내 정보")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if(isEdit==false){
                            HStack{
                                NavigationLink {
                                    SearchUserView()
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                        .tint(.black)
                                        .scaleEffect(0.9)
                                }
                                Menu {
                                    Button("프로필 편집", action: {isEdit = true})
                                    Button("로그아웃", action: viewModel.logOutUser)
                                    Button("계정 삭제", role: .destructive, action: viewModel.deleteAccount)
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .rotationEffect(.init(degrees: 90))
                                        .tint(.black)
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        else{
                            Button{
                                if (editName != "") {
                                    let name = editName==viewModel.user?.userName ? nil : editName
                                    if editName != nil || imageData != nil{
                                        viewModel.editUser(userName: editName, userImage: photoItem)
                                    }
                                    isEdit.toggle()
                                }
                            } label: {
                                Text("수정 완료")
                            }
                            .toolbar{
                                ToolbarItem(placement: .navigationBarLeading){
                                    Button{
                                        imageData = nil
                                        photoItem = nil
                                        isEdit.toggle()
                                    } label: {
                                        Text("수정 취소")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if showPopup {
                Text(errorMessage)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
                  //  .transition(.move(edge: .top))
                    .zIndex(1)
            }
        }
        .onAppear{
            viewModel.userListener(viewModel.currentUID)
        }
    }
    func image(from asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        let imageManager = PHImageManager.default()
        imageManager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFill, options: options) { (image, info) in
            completion(image)
        }
    }
}


struct EditTextProfile: View {
    let text: String
    @Binding var editText: String?
    let item: String
    let isEditable: Bool
    
    var body: some View {
      if isEditable {
          if (item == "자기소개"){
              TextEditor(text: Binding<String>(
                                              get: { self.editText ?? "" },
                                              set: { self.editText = $0.isEmpty ? nil : $0 }
                                          ))
                                  .padding()
                                  .frame(width:UIScreen.main.bounds.width - 30, height: UIScreen.main.bounds.height/3)
                                  .background(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5),lineWidth: 1.5))
                                  .onAppear{
                                      editText = text
                                  }
                                  .onDisappear{
                                      if editText == text{
                                          editText = nil
                                      }
                                  }
          }
          else if(item == "닉네임"){
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
          }
      } else {
          if (item == "닉네임"){
                      Text(text)
                  .font(.title3)
                  .fontWeight(.semibold)
                  .padding(.vertical,10)
          }
          else if(item == "자기소개"){
                  Text(text)
                  .frame(minWidth: 10, maxWidth:335 , minHeight: 150, maxHeight: 150, alignment: .topLeading)
                  .padding(.vertical,-8)
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

struct EditInterestProfile : View{
    var isEditable : Bool
    @State var text = ""
    @State var interests : [[Interests]] = []
//    @State private var showPopup = false
    var showPopup : (String)->()
    
    
    var body : some View{
        if(isEditable==true){
            VStack(spacing:25){
                VStack(spacing:10){
                    ForEach(interests.indices,id: \.self){index in
                        HStack{
                            ForEach(interests[index].indices,id: \.self){interestIndex in
                                HStack{
                                    Text(interests[index][interestIndex].interestText)
                                    Image(systemName:"xmark")
                                }
                                .padding(.vertical,10)
                                .padding(.horizontal)
                                .background(Capsule().stroke(Color.black,lineWidth: 1))
                                .lineLimit(1)
                                .overlay(
                                    GeometryReader{reader -> Color in
                                        
                                        let maxX = reader.frame(in: .global).maxX
                                        
                                        //
                                        if (maxX > UIScreen.main.bounds.width - 70 && !interests[index][interestIndex].isExceeded){
                                            DispatchQueue.main.async{
                                                interests[index][interestIndex].isExceeded = true
                                                let lastItem =
                                                interests[index][interestIndex]
                                                interests.append([lastItem])
                                                interests[index].remove(at:interestIndex)
                                            }
                                        }
                                        
                                        return Color.clear
                                    },
                                    alignment: .trailing
                                )
                                .clipShape(Capsule())
                                .onTapGesture{
                                    interests.remove(at:index)
                                }
                            }
                        }
                    }
                }
                .padding()
                .frame(width:UIScreen.main.bounds.width - 30, height: UIScreen.main.bounds.height/3)
                .background(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5),lineWidth: 1.5))
                VStack{
                    TextField("최대 8글자로 작성해주세요", text: $text)
                        .onReceive(text.publisher.collect()) {
                            let filtered = String($0.prefix(8))
                            if text != filtered {
                                text = filtered
                            }
                        }
                        .padding()
                        .frame(width:UIScreen.main.bounds.width - 30,height: 50 )
                        .background(RoundedRectangle(cornerRadius: 15).stroke(Color.gray.opacity(0.5),lineWidth: 1.5))
                    Button{
                        if interests.flatMap({ $0 }).count < 8{
                            if interests.isEmpty{
                                interests.append([])
                            }
                            
                            withAnimation(.default){
                                interests[interests.count - 1].append(Interests(interestText: text))
                                text = ""
                            }
                        }
                        else {
                            showPopup("최대 8개까지에요")
                            
                            //                                    withAnimation(.easeInOut){
                            //                                    showPopup = true
                            //                                        }
                            //
                            //
                            //                                           DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            //                                               withAnimation(.easeInOut){
                            //                                                   showPopup = false
                            //                                               }
                            //                                           }
                                                                   }
                        } label: {
                            Text("추가하기")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.vertical,10)
                                .frame(width:UIScreen.main.bounds.width - 30)
                                .background(Color.blue)
                                .cornerRadius(15)
                        }
                        
                        .disabled(text=="")
                        .opacity(text == "" ? 0.45 : 1)
                        
                        //                    if showPopup {
                        //                                    Text("최대 8개까지에요")
                        //                                        .fontWeight(.semibold)
                        //                                        .foregroundColor(.white)
                        //                                        .padding()
                        //                                        .background(Color.black)
                        //                                        .cornerRadius(10)
                        //                                      //  .transition(.move(edge: .top))
                        //                                        .zIndex(1)
                        //                    }
                    }
                }
                .padding()
            }
    }
}





struct GaugeView: View {
    @Binding var progress: CGFloat
    private let strokeWidth: CGFloat = 10
   @State private var isShownToolTip = false
    
    var body: some View {
        GeometryReader{ geometry in
            ZStack {
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                    .rotation(Angle(degrees: 180))
                    .foregroundColor(.gray.opacity(0.3))
                
                Circle()
                    .trim(from: 0.0, to: progress * 0.5)
                    .stroke(style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                    .rotation(Angle(degrees: 180))
                    .foregroundColor(Color(red: 1.0 - Double(progress), green: Double(progress), blue: 0.0))
                Text(ratingText(for: progress))
                    .font(.title)
                    .font(.system(size:20))
                    .padding(.top, -10)
                Button{
                    isShownToolTip.toggle()
                } label: {
                    Spacer()
                        .frame(width: 20)
                    HStack(spacing:0) {
                        Text("평가게이지")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .underline(true, color: .black)
                        
                        Image(systemName: "info.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                            .foregroundColor(.black)
                    }
                }
                .offset(x:-120,y:-100)
                
                if isShownToolTip {
                    Text("매너게이지는 다른 사용자들로부터 받은 평가를 분석하여 평균적으로 나타낸 사용의 매너 지표입니다.")
                        .font(.system(size: 12))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .position(x: geometry.size.width * 0.25, y: geometry.size.height * 0.26)
                }
            }
            .scaleEffect(1.2)
        }
    }
    
    func ratingText(for progress: CGFloat) -> String {
           switch progress {
           case 0...0.2:
               return " 최악이에요!😡"
           case 0.2...0.4:
               return " 비매너에요😞"
           case 0.4...0.6:
               return " 괜찮아요🙂"
           case 0.6...0.8:
               return " 친철해요😊"
           default:
               return "  앗,완벽해요!😍 "
           }
       }
}


