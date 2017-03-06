//
//  HealthKitManagerDelegate.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 03/03/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import Foundation

// For usage of weak reference, this protocol needs to be class-bound
protocol HealthKitManagerDelegate: class {

    func onHKAuthorization(success: Bool, error: Error?)
    
}
