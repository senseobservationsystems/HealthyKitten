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
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Swift.Void){
        //TODO:// parameterise sampleType?
        let sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        healthStore.requestAuthorization(toShare: nil, read: [sampleType]) {
            success, error in
            
            completion(success, error)
        }
    }
    
    func startObservingDailyStepCount(completion: @escaping (Double?, Error?) -> Swift.Void) {
        //TODO:// parameterise sampleType?
        let sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) {
            query, completionHandler, error in
            
            guard error == nil else {
                // Perform Proper Error Handling Here...
                print("\(#function) \(error) ***")
                abort()
            }

            self.queryDailyStepCount(completion: completion)
            
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
    
    func queryDailyStepCount(completion: @escaping (Double?, Error?) -> Swift.Void) {
        let sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!

        let (startDate, endDate) = self.getStartEndDate()
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: endDate,
                                                    options: .strictEndDate)
        
        let query = HKStatisticsQuery(quantityType: sampleType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) {
            query, result, error in
                                        
            guard result != nil else {
                print("\(#function): result is \(result)")
                completion(nil, error)
                return
            }
            
            let totalStepCount = self.getTotalStepCount(from: result!)
            
            completion(totalStepCount, error)
        }
        
        healthStore.execute(query)
        
        print("\(#function):\(NSDate()):\(query)")
    }
    
    func getStartEndDate() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.startOfDay(for: endDate)
        
        print("startDate: \(startDate)")
        print("endDate: \(endDate)")
        
        return (startDate, endDate)
    }
    
    func getTotalStepCount(from result: HKStatistics) -> Double{
        var totalStepCount = 0.0
        
        if let quantity = result.sumQuantity() {
            let unit = HKUnit.count()
            totalStepCount = quantity.doubleValue(for: unit)
        }
        
        return totalStepCount
    }
    
    
}
