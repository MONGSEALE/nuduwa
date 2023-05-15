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
    @State var editName: String = ""
    
    @Binding var isEdit: Bool
    
    let user: User

    var onEdit: (String?, PhotosPickerItem?)->()
    

    var body: some View {
        NavigationStack{
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack{
                    HStack(spacing: 12){
                        ZStack{
                            if let imageData,
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }else{
                                WebImage(url: user.userImage).placeholder{ProgressView()}
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
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
                        
                        
                        VStack(alignment: .leading, spacing: 6){
                            EditText(text: user.userName ?? "", editText: $editName, item: "닉네임을 입력해주세요", isEditable: isEdit)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(user.userEmail ?? "")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(3)
                        }
                        .hAlign(.leading)
                    }
                    HStack{
                        VStack{
                            Text("172")
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
                            Text("친구 목록")
                                .font(.system(size:15))
                                .fontWeight(.light)
                                .foregroundColor(.gray)
                        }
                        VStack{
                            
                        }
                    }
                }
                .padding(15)
            }
            if isEdit{
                HStack{
                    Button(action: {
                        if editName != "" {
                            let name = editName==user.userName ? nil : editName
                            onEdit(name, photoItem)
                            isEdit.toggle()
                        }
                    }){
                        CustomButtonText(text: "수정 완료", backgroundColor: .blue)
                    }
                    Button(action: {
                        imageData = nil
                        photoItem = nil
                        isEdit.toggle()
                    }){
                        CustomButtonText(text: "수정 취소", backgroundColor: .red)
                    }
                }
                .padding(.bottom,20)
            }
            
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

