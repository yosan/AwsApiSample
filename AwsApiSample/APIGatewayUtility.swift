//
//  APIGatewayUtility.swift
//  AwsApiSample
//
//  Created by Takahashi Yosuke on 2016/12/19.
//  Copyright © 2016年 Takahashi Yosuke. All rights reserved.
//

import UIKit

class APIGatewayUtility {
    
    enum ISO8601Format: String {
        case day = "yyyyMMdd"
        case second = "yyyyMMdd'T'HHmmss'Z'"
    }
    
    class func utcDateString(format: ISO8601Format, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format.rawValue
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: date)
    }
    
    class func userAgent() -> String {
        let systemName = UIDevice.current.systemName.replacingOccurrences(of: " ", with: "-")
        let systemVersion = UIDevice.current.systemVersion
        let localeIdentifier = Locale.current.identifier
        return "aws-sdk-iOS/2.4.10 \(systemName)/\(systemVersion) \(localeIdentifier)"
    }
    
    class func sha256(source: String) -> String {
        let cstr = source.cString(using: String.Encoding.utf8)!
        var chars = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(
            cstr,
            CC_LONG(source.lengthOfBytes(using: String.Encoding.utf8)),
            &chars
        )
        return chars.map { String(format: "%02X", $0) }.reduce("", +).lowercased()
    }
    
    class func sha256HMacWith(source: Data, key: Data) -> Data {
        let context = UnsafeMutablePointer<CCHmacContext>.allocate(capacity: 1)
        
        let keyData = key as NSData
        CCHmacInit(context, CCHmacAlgorithm(kCCHmacAlgSHA256), keyData.bytes, keyData.length)
        
        let data = source as NSData
        CCHmacUpdate(context, data.bytes, data.length)
        
        var digest = Array<UInt8>(repeating:0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmacFinal(context, &digest)
        
        return Data(bytes: digest)
    }
}
