

import SwiftUI
import Firebase
import FirebaseFirestore

struct SearchUserView: View {
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    
    @State var isEdit: Bool = false ///추후 삭제
    
    var body: some View {
        List{
            ForEach(fetchedUsers){ user in
                NavigationLink {
                    ProfilePreview(user: user, isCurrent: false, showChatButton: true)
                } label: {
                    Text(user.userName)
                        .font(.callout)
                        .hAlign(.leading)
                }
            }
        }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("유저 검색")
            .searchable(text: $searchText)
            .onSubmit(of: .search, {
                /// - Fetch User From Firebase
                Task{await searchUsers()}
            })
            .onChange(of: searchText, perform: { newValue in
                if newValue.isEmpty{
                    fetchedUsers = []
                }
            })
            /*
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel"){
                        dismiss()
                    }
                    .tint(.black)
                }
            }
            */
    }

    func searchUsers()async{
        do{
            let documents = try await Firestore.firestore().collection("Users")
                .whereField("userName", isGreaterThanOrEqualTo: searchText)
                .whereField("userName", isLessThanOrEqualTo:"\(searchText)\u{f8ff}")
                .getDocuments()

            let users = try documents.documents.compactMap{ doc -> User? in
                try doc.data(as: User.self)
            }
            await MainActor.run(body: {
                fetchedUsers = users
            })
        }catch{
            print(error.localizedDescription)
        }
    }
}
