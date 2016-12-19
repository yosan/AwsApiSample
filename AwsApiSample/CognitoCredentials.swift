//
//  CognitoCredentials.swift
//  AwsApiSample
//
//  Created by Takahashi Yosuke on 2016/12/19.
//  Copyright © 2016年 Takahashi Yosuke. All rights reserved.
//

import Foundation

struct CognitoCredentials {
    
    let accessKeyId: String
    let expiration: TimeInterval
    let secretKey: String
    let sessionToken: String
    
    init?(with json: [AnyHashable : Any]) {
        guard
            let credentials = json["Credentials"] as? [String : Any],
            let accessKeyId = credentials["AccessKeyId"] as? String,
            let expiration = credentials["Expiration"] as? TimeInterval,
            let secretKey = credentials["SecretKey"] as? String,
            let sessionToken = credentials["SessionToken"] as? String
            else { return nil }
        
        self.accessKeyId = accessKeyId
        self.expiration = expiration
        self.secretKey = secretKey
        self.sessionToken = sessionToken
    }
}
