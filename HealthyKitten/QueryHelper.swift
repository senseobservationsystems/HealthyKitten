//
//  QueryFactory.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 03/03/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import Foundation
import HealthKit
import UIKit

class QueryHelper {
    
    enum Period {
        case daily
        case weekly
    }
    
    class func getStepCountQuery(for period: Period,
                                 handler: @escaping (Double?) -> Swift.Void) -> HKQuery {
        
        
        let sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let predicate = getPredicate(for: period)
        
        return HKStatisticsQuery(quantityType: sampleType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum){
            query, result, error in
                                        
            // Callback on receving the result
            guard error == nil, result != nil else { return }
            // Handler expects a Double value as a parameter
            handler(self.getTotalStepCount(from: result!))
        }
        
    }
    
    class func getSleepQuery(for period: Period,
                                 handler: @escaping (Double?) -> Swift.Void) -> HKQuery {
        let sampleType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        let predicate = getPredicate(for: period)

        return HKSampleQuery(sampleType: sampleType!,
                             predicate: predicate,
                             limit: HKObjectQueryNoLimit,
                             sortDescriptors: nil){
            query, results, error in
                                
            guard error == nil, results != nil else { return }
            // Handler expects a Double value as a parameter
            handler(self.getTotalSleep(from: results!))
        }
    }
    

    class func getPredicate(for period: Period) -> NSPredicate {
        let (start, end) = getStartEndDate(period)
        return HKQuery.predicateForSamples(withStart: start,
                                           end: end,
                                           options: .strictEndDate)
    }
    
    class func getStartEndDate(_ period: Period) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let endDate: Date
        let startDate: Date
        
        switch (period) {
            case .daily:
                endDate = Date()
                startDate = calendar.startOfDay(for: endDate)
                break
            case .weekly:
                endDate = Date()
                let aWeekAgo = endDate.addingTimeInterval(-7*24*60*60)
                startDate = calendar.startOfDay(for: aWeekAgo)
                break
        }
        
        print("startDate: \(startDate)")
        print("endDate: \(endDate)")
        
        return (startDate, endDate)
    }
    
    class func getTotalSleep(from results: [HKSample]) -> Double {
        print(results)
        let sumSleepHours = {(result: Double, sample: HKSample) -> Double in
            if sample is HKCategorySample &&
                (sample as! HKCategorySample).value == HKCategoryValueSleepAnalysis.inBed.rawValue {
                let duration = (sample.endDate.timeIntervalSince(sample.startDate) / (60 * 60) )
                return result + duration
            } else {
                return 0.0
            }
        }
        
        return results.reduce(0.0, sumSleepHours)
    }
    
    class func getTotalStepCount(from result: HKStatistics) -> Double{
        guard let quantity = result.sumQuantity() else { return 0.0 }
        
        let unit = HKUnit.count()
        return quantity.doubleValue(for: unit)
    }
}
