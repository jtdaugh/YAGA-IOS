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
    class var sharedManager : NetworkManager {
        get {
            return _NetworkManagerSharedInstance
        }
    }
    
    var userData = Dictionary<String, AnyObject>()
    
    func userIsLoggedIn() -> Bool {
        return false
    }
    
    func saveData(data: AnyObject?, key: String) {
        if let newData: AnyObject = data {
            self.userData[key] = newData
        }
    }
}
