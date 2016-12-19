//
//  APIGatewayInvoker.swift
//  AwsApiSample
//
//  Created by Takahashi Yosuke on 2016/12/19.
//  Copyright © 2016年 Takahashi Yosuke. All rights reserved.
//

import Foundation

class APIGatewayInvoker {
    
    /// Timeout seconds
    fileprivate static let timeout: Double = 30.0
    
    /// Region to access
    let region: String
    
    /// Initializer
    ///
    /// - Parameter region: region
    init(region: String) {
        self.region = region
    }
    
    /// GetId from Cognito Identity Pool
    ///
    /// - Parameters:
    ///   - identityPoolId: ID of Cognito Identity Pool
    ///   - completion: callbacks IdentityId or error
    func cognitoGetId(identityPoolId: String, completion: @escaping (String?, Error?) -> Void) {
        let now = Date()
        
        let headers: [String : String] = [
            "Content-Type" : "application/x-amz-json-1.1",
            "X-AMZ-TARGET" : "com.amazonaws.cognito.identity.model.AWSCognitoIdentityService.GetId",
            "X-AMZ-DATE" : APIGatewayUtility.utcDateString(format: .second, date: now)
        ]
        let bodyJson = [ "IdentityPoolId" : identityPoolId ]
        
        post(urlString: "https://cognito-identity.ap-northeast-1.amazonaws.com",
             headers: headers,
             bodyJson: bodyJson)
        { (data, error) in
                guard let data = data else { completion(nil, error); return }
                let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : String]
                completion(json["IdentityId"], nil)
        }
    }
    
    
    /// Get credentials from Cognito
    ///
    /// - Parameters:
    ///   - identityId: ID which needs credentials
    ///   - completion: callbacks credentials or nil
    func cognitoGetCredentialsForIdentity(identityId: String, completion: @escaping (CognitoCredentials?, Error?) -> Void) {
        let now = Date()
        
        let headers: [String : String] = [
            "Content-Type" : "application/x-amz-json-1.1",
            "X-AMZ-TARGET" : "com.amazonaws.cognito.identity.model.AWSCognitoIdentityService.GetCredentialsForIdentity",
            "X-AMZ-DATE" : APIGatewayUtility.utcDateString(format: .second, date: now)
        ]
        let bodyJson = [ "IdentityId" : identityId ]
        
        post(urlString: "https://cognito-identity.ap-northeast-1.amazonaws.com",
             headers: headers,
             bodyJson: bodyJson)
        { (data, error) in
            guard let data = data else { completion(nil, error); return }
            
            let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : Any]
            completion(CognitoCredentials(with: json), nil)
        }
    }
    
    
    /// Call API Gateway
    ///
    /// - Parameters:
    ///   - urlString: URL
    ///   - credentials: credentials
    ///   - completion: callbacks data or error
    func invoke(urlString: String, credentials: CognitoCredentials, apiKey: String? = nil, completion: @escaping (Data?, Error?) -> Void) {
        let now = Date()
        
        let host = URL(string: urlString)!.host!
        let timeStamp = APIGatewayUtility.utcDateString(format: .second, date: now)
        var headers: [String : String] = [
            "Accept" : "application/json",
            "Content-Type" : "application/json",
            "Host" : host,
            "User-Agent" : APIGatewayUtility.userAgent(),
            "X-Amz-Date" : timeStamp,
            "X-Amz-Security-Token" : credentials.sessionToken
        ]
        
        if let apiKey = apiKey {
            headers["x-api-key"] = apiKey
        }

        let signParameter = SignParameter(
            date: now,
            region: region,
            service: "execute-api",
            accessKey: credentials.accessKeyId,
            secretKey: credentials.secretKey)
        get(urlString: urlString, headers: headers, signParameter: signParameter, completion: completion)
    }
}

private extension APIGatewayInvoker {
    
    struct SignParameter {
        let date: Date
        let region: String
        let service: String
        let accessKey: String
        let secretKey: String
    }
    
    func get(urlString: String, headers: [String : String], signParameter: SignParameter? = nil, completion: @escaping (Data?, Error?) -> Void) {
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        
        if let signParameter = signParameter {
            request = AWSV4Signer.sign(request: request,
                                       date: signParameter.date,
                                       region: signParameter.region,
                                       service: signParameter.service,
                                       accessKey: signParameter.accessKey,
                                       secretKey: signParameter.secretKey)
        }
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            completion(data, error)
        }
        task.resume()
        
    }
    
    func post(urlString: String, headers: [String : String], bodyJson: [String : String], completion: @escaping (Data?, Error?) -> Void) {
        var request = URLRequest(
            url: URL(string: "https://cognito-identity.ap-northeast-1.amazonaws.com")!,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: APIGatewayInvoker.timeout)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyJson, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            completion(data, error)
        }
        task.resume()
    }
    
}
