//
//  StorageManager.swift
//  MessengerApp
//
//  Created by Ayman  on 6/20/20.
//  Copyright © 2020 Ayman . All rights reserved.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    // so we can get an instance form this class and use its functions.
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /*
     /images/user_email_profile_picture.png
     /images/a-a-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// upload a picture to firebase storage and returns completion with url string to download.
    public func uploadProfilePicture(with data:Data, fileName: String,completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil , completion: {metadata , error in
            guard  error == nil else {
                // upload failed.
                print("failed to upload the picture to firebase storage.")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("images/\(fileName)").downloadURL(completion: {url , error in
                guard let url = url else {
                    print("failed to get the download Url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("download url returned \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    /// download the image form firebase storage.
    public func downloadUrl(for path: String , completion: @escaping (Result<URL, Error>) -> Void){
        let reference = storage.child(path)
        
        reference.downloadURL(completion: {url , error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
    
    /// upload an image that will be sent to a conversation message.
    public func uploadMessagePhoto(with data:Data, fileName: String,completion: @escaping UploadPictureCompletion) {
           storage.child("message_images/\(fileName)").putData(data, metadata: nil , completion: {[weak self] metadata , error in
               guard  error == nil else {
                   // upload failed.
                   print("failed to upload the picture to firebase storage.")
                   completion(.failure(StorageErrors.failedToUpload))
                   return
               }
               self? .storage.child("message_images/\(fileName)").downloadURL(completion: {url , error in
                   guard let url = url else {
                       print("failed to get the download Url")
                       completion(.failure(StorageErrors.failedToGetDownloadUrl))
                       return
                   }
                   let urlString = url.absoluteString
                   print("download url returned \(urlString)")
                   completion(.success(urlString))
               })
           })
       }
    
    /// upload an video that will be sent to a conversation message.
       public func uploadMessageVideo(with fileUrl: URL, fileName: String,completion: @escaping UploadPictureCompletion) {
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil , completion: {[weak self] metadata , error in
                  guard  error == nil else {
                      // upload failed.
                      print("failed to upload the video file to firebase storage.")
                      completion(.failure(StorageErrors.failedToUpload))
                      return
                  }
                  self?.storage.child("message_videos/\(fileName)").downloadURL(completion: {url , error in
                      guard let url = url else {
                          print("failed to get the download Url")
                          completion(.failure(StorageErrors.failedToGetDownloadUrl))
                          return
                      }
                      let urlString = url.absoluteString
                      print("download url returned \(urlString)")
                      completion(.success(urlString))
                  })
              })
          }
    
    public enum StorageErrors:Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
}
