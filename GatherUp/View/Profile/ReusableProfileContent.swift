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
    @Binding var isEdit: Bool
    @State private var progress: CGFloat = 0.7
    
    let user: User

    var onEdit: (String?, PhotosPickerItem?)->()
    @StateObject var viewModel: ProfileViewModel = .init()
    

    var body: some View {
        NavigationStack{
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(){
                    HStack(spacing:0){
                        ZStack{
                            if let imageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
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
                        
                        EditTextProfile(text: user.userName , editText: $editName, item: "닉네임", isEditable: isEdit)
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
                                let name = editName==user.userName ? nil : editName
                                onEdit(name, photoItem)
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
                .frame(height: 150) // or whatever fixed height you want
                .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
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

struct GaugeView: View {
    @Binding var progress: CGFloat
    private let strokeWidth: CGFloat = 10
   @State private var isShownToolTip = false
    
    var body: some View {
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
        }
        .scaleEffect(1.2)
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

struct ToolTip : View {
    var body : some View{
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = width
            Path { path in
                path.move(to:CGPoint(x:40,y:300))
                path.addLine(to:CGPoint(x:width - 40,y:300))
                path.addLine(to: CGPoint(x:width - 40,y:400))
                path.addLine(to:CGPoint(x: width - 60,y:400))
                path.addLine(to: CGPoint(x: width - 80,y:440))
                path.addLine(to: CGPoint(x: width - 80, y: 400))
                path.addLine(to:CGPoint(x:40,y:400))
                path.closeSubpath()
            }
            .fill(Color("ToolTip"))
            Path { path in
                           path.move(to:CGPoint(x:40,y:300))
                           path.addLine(to:CGPoint(x:width - 40,y:300))
                           path.addLine(to: CGPoint(x:width - 40,y:400))
                           path.addLine(to:CGPoint(x: width - 60,y:400))
                           path.addLine(to: CGPoint(x: width - 80,y:440))
                           path.addLine(to: CGPoint(x: width - 80, y: 400))
                           path.addLine(to:CGPoint(x:40,y:400))
                           path.closeSubpath()
                       }
             .stroke(Color.black,lineWidth: 1)
        }
    }
}

struct ToolTip_Previews: PreviewProvider{
    static var previews: some View{
        ToolTip()
    }
}

