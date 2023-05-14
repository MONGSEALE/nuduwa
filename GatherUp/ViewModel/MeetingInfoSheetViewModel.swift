//
//  MeetingInfoSheetViewModel.swift
//  GatherUp
//
//  Created by DaelimCI00007 on 2023/05/09.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

class MeetingInfoSheetViewModel: FirebaseViewModelwithMeetings {

    @Published var isDelete: Bool = false

    /// 모임 데이터 가져오기
    func meetingListner(meetingID: String){
        print("meetingListner")
        isLoading = true
        Task{
            let doc = db.collection(strMeetings).document(meetingID)
            meetingListener = doc.addSnapshotListener{ snapshot, error in
                if let snapshot {
                    if snapshot.exists{
                        if let updatedMeeting = try? snapshot.data(as: Meeting.self){
                            self.meeting = updatedMeeting
                        }
                    }else{
                        self.isDelete = true
                    }
                }
                self.isLoading = false
            }
        }
    }
    /// 다른 리스너와 겹치지 않도록 하나더 만듬
    func removeMeetingListener(){
        if let meetingListener{
            meetingListener.remove()
            self.meetingListener = nil
        }
    }
}

