//
//  HealthKitManager.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 16/02/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import Foundation
import HealthKit

class HealthKitManager {
    
    private let healthStore = HKHealthStore()
    var typesToWrite: Set<HKSampleType>
    var typesToRead: Set<HKQuantityTypeIdentifier>
    var objectTypesToRead: Set<HKObjectType>? {
        get {
            var objectTypes = Set<HKObjectType>()
            for type in typesToRead {
                guard let objectType = HKObjectType.quantityType(forIdentifier: type) else {
                    continue
                }
                objectTypes.insert(objectType)
            }
            return objectTypes
        }
    }
    
    init(typesToWrite: Set<HKSampleType> = Set<HKSampleType>(), typesToRead: Set<HKQuantityTypeIdentifier> = Set<HKQuantityTypeIdentifier>()){
        self.typesToWrite = typesToWrite
        self.typesToRead = typesToRead
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Swift.Void){
        healthStore.requestAuthorization(toShare: self.typesToWrite, read: self.objectTypesToRead) {
            success, error in
            
            guard error == nil else {
                print("\(#function): \(error)")
                return
            }
            completion(success, error)
        }
    }
    
    func startObserving(withQuery onEventQuery: HKQuery) {
        //TODO:// parameterise sampleType?
        let sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) {
            query, completionHandler, error in
            
            guard error == nil else {
                // Perform Proper Error Handling Here...
                print("\(#function) \(error) ")
                abort()
            }
            // execute query
            self.healthStore.execute(onEventQuery)
            
            // If you have subscribed for background updates you must call the completion handler here.
            completionHandler()
        }
        self.healthStore.execute(query)
        self.healthStore.enableBackgroundDelivery(for: sampleType,
                                                  frequency: .immediate) {
                                                    (success, error) in
                                                    print("Background Delivery completed")
        }
    }
    

    
    
}
