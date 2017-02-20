//
//  DailyStepCountQuery.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 20/02/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import Foundation
import HealthKit

class DailyStepCountQuery: HKStatisticsQuery {

    convenience init(completion: @escaping (Double?, Error?) -> Swift.Void ){
        let (startDate, endDate) = DailyStepCountQuery.getStartEndDate()
        let sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: endDate,
                                                    options: .strictEndDate)
        
        
        self.init(quantityType: sampleType, quantitySamplePredicate: predicate, options: .cumulativeSum) {
            query, result, error in
            
            guard error == nil, result != nil else {
                completion(nil, error)
                return
            }
            
            let totalStepCount = DailyStepCountQuery.getTotalStepCount(from: result!)
            completion(totalStepCount, error)
        }
    }
    
    class func getStartEndDate() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.startOfDay(for: endDate)
        
        print("startDate: \(startDate)")
        print("endDate: \(endDate)")
        
        return (startDate, endDate)
    }
    
    class func getTotalStepCount(from result: HKStatistics) -> Double{
        var totalStepCount = 0.0
        
        if let quantity = result.sumQuantity() {
            let unit = HKUnit.count()
            totalStepCount = quantity.doubleValue(for: unit)
        }
        
        return totalStepCount
    }
}
