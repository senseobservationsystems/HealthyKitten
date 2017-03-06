//
//  HealthKitManager.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 16/02/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import Foundation
import HealthKit

final class HealthKitManager {

    let healthStore = HKHealthStore()
    var typesToWrite: Set<HKSampleType>
    var typesToRead: Set<HKObjectType>

    fileprivate var observers: [(HealthKitManager) -> ()] = []

    
    init(typesToWrite: Set<HKSampleType> = Set<HKSampleType>(), typesToRead: Set<HKObjectType> = Set<HKObjectType>()){
        self.typesToWrite = typesToWrite
        self.typesToRead = typesToRead
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Swift.Void){
        healthStore.requestAuthorization(toShare: self.typesToWrite,
                                         read: self.typesToRead) {
            success, error in
            
            guard error == nil else {
                print("\(#function): \(error)")
                return
            }
            completion(success, error)
        }
    }
    
    func startBackgroundDelivery(forQuantityType quantityType: HKQuantityTypeIdentifier,
                                 frequency: HKUpdateFrequency,
                                 onEvent: @escaping (Error?) -> Swift.Void) {
        //TODO:// parameterise sampleType?
        let sampleType = HKObjectType.quantityType(forIdentifier: quantityType)!
        
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) {
            query, completionHandler, error in
            
            // execute query
            onEvent(error)
            
            // completionHandler that is given from background delivery. Needs to call to make sure that this callback is called next time again.
            completionHandler()
        }
        self.healthStore.execute(query)
        self.healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate){
            (success, error) in
            print("Background Delivery completed")
        }
    }
    
    func startBackgroundDelivery(forSampleType sampleType: HKSampleType,
                                 frequency: HKUpdateFrequency,
                                 onEvent: @escaping (Error?) -> Swift.Void) {
        
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) {
            query, completionHandler, error in
            
            // execute query
            onEvent(error)
            
            // completionHandler that is given from background delivery. Needs to call to make sure that this callback is called next time again.
            completionHandler()
        }
        self.healthStore.execute(query)
        self.healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate){
            (success, error) in
            print("Background Delivery completed")
        }
    }
}

