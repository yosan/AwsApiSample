//
//  ViewController.swift
//  AwsApiSample
//
//  Created by Takahashi Yosuke on 2016/12/17.
//  Copyright © 2016年 Takahashi Yosuke. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let invoker = APIGatewayInvoker(region: "<REGION>")
        invoker.cognitoGetId(identityPoolId: "<IDENTITY POOL ID>") { (identityId, error) in
            guard let identityId = identityId else { return }
            
            invoker.cognitoGetCredentialsForIdentity(identityId: identityId, completion: { (credentials, error) in
                guard let credentials = credentials else { return }
                
                invoker.invoke(
                    urlString: "<API URL>",
                    query: [:],
                    credentials: credentials,
                    completion: { (data, error) in
                        guard let data = data else { return }
                        print(String(data: data, encoding: .utf8)!)
                })
            })
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

