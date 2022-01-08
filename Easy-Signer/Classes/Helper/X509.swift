//
//  X509.swift
//  Easy-Signer
//
//  Created by crazyball on 2022/1/8.
//

import Foundation
import OpenSSL

enum X509Type {
    case der
    case pem
}

class X509 {
    
    private let ptr: OpaquePointer?
    init?(data: Data, type: X509Type){
        self.ptr = data.withUnsafeBytes { (ptr) -> OpaquePointer? in
            let bio = BIO_new_mem_buf(ptr.baseAddress, CInt(ptr.count))!
            defer {
                BIO_free(bio)
            }
            switch type {
            case .der:
                return d2i_X509_bio(bio, nil)
            case .pem:
                return PEM_read_bio_X509(bio, nil, nil, nil)
            }
        }
        guard self.ptr != nil else {
            return nil
        }
    }
    
    
    var commonName: String? {
        guard let subjectName = X509_get_subject_name(self.ptr) else {
            return nil
        }

        var lastIndex: CInt = -1
        var nextIndex: CInt = -1
        repeat {
            lastIndex = nextIndex
            nextIndex = X509_NAME_get_index_by_NID(subjectName, NID_commonName, lastIndex)
        } while nextIndex >= 0
        guard lastIndex >= 0 else {
            return nil
        }
        guard let nameData = X509_NAME_ENTRY_get_data(X509_NAME_get_entry(subjectName, lastIndex)) else {
            return nil
        }
        var encodedName: UnsafeMutablePointer<UInt8>? = nil
        let stringLength = ASN1_STRING_to_UTF8(&encodedName, nameData)

        guard let namePtr = encodedName else {
            return nil
        }
        let arr = [UInt8](UnsafeBufferPointer(start: namePtr, count: Int(stringLength)))
        free(namePtr)
        return String(data: Data(arr), encoding: .utf8)
    }
    
    var sha1: String {
        var len: UInt32 = 0
        let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(EVP_MAX_MD_SIZE))
        X509_digest(self.ptr, EVP_sha1(), ptr, &len)
        let arr = [UInt8](UnsafeMutableBufferPointer(start: ptr, count: Int(len)))
        let str = arr.map{ String(format: "%02x", $0) }.joined(separator: "")
        free(ptr)
        return str.uppercased()
    }
    
    var md5: String {
        var len: UInt32 = 0
        let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(EVP_MAX_MD_SIZE))
        X509_digest(self.ptr, EVP_md5(), ptr, &len)
        let arr = [UInt8](UnsafeMutableBufferPointer(start: ptr, count: Int(len)))
        let str = arr.map{ String(format: "%02x", $0) }.joined(separator: "")
        free(ptr)
        return str.uppercased()
    }
}
