//
//  YANetworkManager.swift
//  Pic6
//
//  Created by Iegor on 12/15/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

import UIKit

private let _NetworkManagerSharedInstance = NetworkManager()

class NetworkManager: NSObject {
    class var sharedInstance : NetworkManager {
        get {
            return _NetworkManagerSharedInstance
        }
    }
    
    func userIsLoggedIn() -> Bool {
        return true
    }
}
