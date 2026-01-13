//
//  StorageController.swift
//  TravelBookServer
//
//  Created by ddorsat on 13.01.2026.
//

import Vapor
import SotoS3

struct StorageController {
    func uploadBulkImages(_ req: Request) async throws -> [String] {
        guard let s3 = req.application.storage[S3Key.self] else {
            throw Abort(.internalServerError, reason: "S3 not configured")
        }
        
        let input = try req.content.decode(BulkUpload.self)
        var uploadedURLs: [String] = []
        let bucketName = "travelbookstorage"
        
        for file in input.files {
            let filename = "\(UUID().uuidString).\(file.extension ?? "jpg")"
            
            let putRequest = S3.PutObjectRequest(acl: .publicRead,
                                                 body: .byteBuffer(file.data),
                                                 bucket: bucketName,
                                                 contentType: file.contentType?.serialize(),
                                                 key: filename)
            
            _ = try await s3.putObject(putRequest)
            
            let publicURL = "https://storage.yandexcloud.net/\(bucketName)/\(filename)"
            uploadedURLs.append(publicURL)
        }
        
        return uploadedURLs
    }
}


struct ImageUpload: Content {
    var file: File
}

struct BulkUpload: Content {
    var files: [File]
}
