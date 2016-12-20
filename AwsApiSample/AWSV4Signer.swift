//
//  AWSV4Signer.swift
//  AwsApiSample
//
//  Created by Takahashi Yosuke on 2016/12/19.
//  Copyright © 2016年 Takahashi Yosuke. All rights reserved.
//

import Foundation

class AWSV4Signer {
    
    class func sign(
        request: URLRequest,
        date: Date,
        region: String,
        service: String,
        accessKey: String,
        secretKey: String) -> URLRequest {
        
        let headers = request.allHTTPHeaderFields!
        let query = request.url?.query ?? ""
        
        let signedHeaders = headers.keys.map { $0.lowercased() }.sorted { $0 < $1 }.joined(separator: ";")
        let credentialScope = createCredentialScope(date: date, region: region, service: service)
        
        let canonicalRequest = createCanonicalRequest(
            method: request.httpMethod!,
            path: request.url!.path,
            query: query,
            headers: headers,
            signedHeaders: signedHeaders,
            body: "")
        let hashedCanonicalRequest = APIGatewayUtility.sha256(source: canonicalRequest)
        let signedString = createSignedString(date: date, credentialScope: credentialScope, hashedCanonicalRequest: hashedCanonicalRequest)
        
        let signatureKey = createSignatureKey(
            secretKey: secretKey,
            date: date,
            region: region,
            service: service)
        
        let signatureData = APIGatewayUtility.sha256HMacWith(source: signedString.data(using: .utf8)!, key: signatureKey)
        let signature = signatureData.reduce("") {$0 + String(format: "%02x", $1)}
        
        let credential = createCredential(
            accessKey: accessKey,
            credentialScope: credentialScope,
            signedHeaders: signedHeaders,
            signature: signature)
        
        var signedRequest = request
        signedRequest.allHTTPHeaderFields?["Authorization"] = credential
        return signedRequest
    }
}

private extension AWSV4Signer {
    
    class func createCanonicalRequest(
        method: String,
        path: String,
        query: String,
        headers: [String : String],
        signedHeaders: String,
        body: String) -> String {
        
        let canonicalQuery = createCanonicalQuery(from: query)
        let canonicalHeaders = createCanonicalHeaders(from: headers)
        
        let lines: [String] = [
            method,
            path.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!,
            canonicalQuery,
            canonicalHeaders,
            "",
            signedHeaders,
            APIGatewayUtility.sha256(source: body)
        ]
        return lines.joined(separator: "\n")
    }
    
    class func createCanonicalQuery(from query: String) -> String {
        return query.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }
    
    class func createCanonicalHeaders(from headers: [String : String]) -> String {
        let lowerKeyHeaders = headers.reduce([:]) { (result: [String : String], item: (key: String, value: String)) -> [String : String] in
            var result = result
            result[item.key.lowercased()] = item.value
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: " +", with: " ", options: .regularExpression, range: nil)
            return result
        }
        return convertToString(from: lowerKeyHeaders, keyValueSeparator: ":", itemSeparator: "\n")
    }
    
    class func convertToString(
        from dictionary: [String : String],
        keyValueSeparator: String,
        itemSeparator: String) -> String {
        
        let sorted = dictionary.sorted { (item1: (key: String, value: String), item2: (key: String, value: String)) -> Bool in
            return item1.key < item2.key
        }
        
        let keyValues = sorted.map { (item: (key: String, value: String)) -> String in
            return [item.key, item.value].joined(separator: keyValueSeparator)
        }
        return keyValues.joined(separator: itemSeparator)
    }
    
    class func createSignedString(date: Date, credentialScope: String, hashedCanonicalRequest: String) -> String {
        let algorithm = "AWS4-HMAC-SHA256"
        let requestDate = utcDateString(format: "yyyyMMdd'T'HHmmss'Z'", date: date)
        
        let lines: [String] = [
            algorithm,
            requestDate,
            credentialScope,
            hashedCanonicalRequest
        ]
        
        return lines.joined(separator: "\n")
    }
    
    class func createCredentialScope(date: Date, region: String, service: String) -> String {
        return [
            utcDateString(format: "yyyyMMdd", date: date),
            region,
            service,
            "aws4_request"
            ].joined(separator: "/")
    }
    
    class func utcDateString(format: String, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: date)
    }
    
    class func createCredential(
        accessKey: String,
        credentialScope: String,
        signedHeaders: String,
        signature: String) -> String {
        return [
            "AWS4-HMAC-SHA256",
            "Credential=\(accessKey)/\(credentialScope)",
            "SignedHeaders=\(signedHeaders)",
            "Signature=\(signature)"
            ].joined(separator: " ")
    }
    
    class func createSignatureKey(
        secretKey: String,
        date: Date,
        region: String,
        service: String) -> Data {
        let key = ("AWS4" + secretKey).data(using: .utf8)
        let hmacDate = APIGatewayUtility.sha256HMacWith(source: utcDateString(format: "yyyyMMdd", date: date).data(using: .utf8)!, key: key!)
        let hmacRegion = APIGatewayUtility.sha256HMacWith(source: region.data(using: .utf8)!, key: hmacDate)
        let hmacService = APIGatewayUtility.sha256HMacWith(source: service.data(using: .utf8)!, key: hmacRegion)
        let signatureKey = APIGatewayUtility.sha256HMacWith(source: "aws4_request".data(using: .utf8)!, key: hmacService)
        return signatureKey
    }
    
}
