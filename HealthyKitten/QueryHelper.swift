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
        return getStatisticsQuery(period: .daily,
                                  quantityType: .stepCount,
                                  statisticsOption: .cumulativeSum) {
                                    query, result, error in
            // TODO: handler error properly
            guard error == nil, result != nil else { return }
            handler(self.getTotalStepCount(from: result!))
        }
    }
    
    class func getStatisticsQuery(period: Period,
                                  quantityType: HKQuantityTypeIdentifier,
                                  statisticsOption: HKStatisticsOptions,
                                  handler: @escaping (HKStatisticsQuery, HKStatistics?, Error?) -> Swift.Void) -> HKQuery {
        
        let (start, end) = getStartEndDate(period)
        let sampleType = HKObjectType.quantityType(forIdentifier: quantityType)!
        let predicate = HKQuery.predicateForSamples(withStart: start,
                                                    end: end,
                                                    options: .strictEndDate)
        
        let query = HKStatisticsQuery(quantityType: sampleType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum,
                                      completionHandler: handler)
        
        return query
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
    
    class func getTotalStepCount(from result: HKStatistics) -> Double{
        var totalStepCount = 0.0
        
        if let quantity = result.sumQuantity() {
            let unit = HKUnit.count()
            totalStepCount = quantity.doubleValue(for: unit)
        }
        
        return totalStepCount
    }
}
