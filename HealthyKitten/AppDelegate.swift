//
//  AppDelegate.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 10/02/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import UIKit
import UserNotifications
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let healthKitManager = HealthKitManager(typesToRead: [.stepCount])
    /// Stores the sequence of "Health kit sample events" our app received. Possible event types are:
    /// - StepCount
    /// - Sleep
    let eventsStore = UserDefaultsDataStore<SerializableArray<HKSample>>(key: "HealthKitSampleEvents", defaultValue: [])
    
    /// Stores the number of background activity events our app received while it was in the background.
    /// Should be reset to 0 the next time the app comes into the foreground.
    let numberOfEventsReceivedWhileInBackgroundStore = UserDefaultsDataStore<Int>(key: "eventsReceivedWhileInBackground", defaultValue: 0)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {

        // Check UI components are properly set
        guard
            let tabBarController = window?.rootViewController as? UITabBarController,
            let tabBarChildViewControllers = tabBarController.viewControllers, tabBarChildViewControllers.count >= 2,
            let eventsTabNavController = tabBarChildViewControllers[0] as? UINavigationController,
            let eventsViewController = eventsTabNavController.viewControllers.first as? EventsViewController
            //let secondTabNavController = tabBarChildViewControllers[1] as? UINavigationController,
            //let secondViewController = secondTabNavController.viewControllers.first as? SecondViewController
        else {
            preconditionFailure("View controllers not found")
        }
        
        // Set models to controller
        eventsViewController.viewModel = EventsViewModel(store: eventsStore)

        // Set up HealthKit background delivery
        healthKitManager.requestAuthorization { success, error in
            guard error == nil else { abort() }
            self.onHKAuthoriazationGranted()
        }

        // Ask for permission to display alerts and badge numbers on the app icon.
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge], completionHandler: { (granted, error) in
            if (!granted){
                print("\(#function): No notifications? Well, that is fine.")
            }
            if (error != nil) {
                print("\(#function): \(error)")
            }
        })
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        numberOfEventsReceivedWhileInBackgroundStore.value = 0
        application.applicationIconBadgeNumber = numberOfEventsReceivedWhileInBackgroundStore.value
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        print("\(#function)")
    }

    
//    func onHKAuthoriazationGranted(){
//        // Authorization is granted.
//        healthKitManager.startBackgroundDelivery(forQuantityType: .stepCount) { (error) in
//            let query = DailyStepCountQuery { (value, error) in
//                guard error == nil else { return }
//                self.onHKNewDailyStepCount(value: value)
//            }
//            print("\(#function):\(NSDate()):\(query)")
//            self.healthKitManager.healthStore.execute(query as HKStatisticsQuery)
//        }
//    }
    
    
    func onHKAuthoriazationGranted(){
        // Authorization is granted.
        healthKitManager.startBackgroundDelivery(forQuantityType: .stepCount) { (error) in
            let (startDate, endDate) = self.getStartEndDate()
            let sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!
            let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                        end: endDate,
                                                        options: .strictEndDate)
            let query = HKStatisticsQuery(quantityType: sampleType,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) {
                query, result, error in
                
                guard error == nil, result != nil else {
                    print("\(#function): Error:\(error), result:\(result)")
                    return
                }
                
                let totalStepCount = self.getTotalStepCount(from: result!)
                self.onHKNewDailyStepCount(value: totalStepCount)
            }
            self.healthKitManager.healthStore.execute(query)
        }
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
    
    // ====
    
    func onHKNewDailyStepCount(value: Double?) {
        let payload = ["value": value]
        let applicationState = UIApplication.shared.applicationState
        let event = HKSample.StepCount(receivedAt: Date(),
                                       applicationState: applicationState,
                                       payload: payload)
        self.eventsStore.value.elements.insert(event, at: 0)
        
        if applicationState != .active {
            self.sendNotification(event: event)
        }
        
        print("Horray! \(payload)")
    }
    
    func sendNotification(event: HKSample){
        self.numberOfEventsReceivedWhileInBackgroundStore.value += 1
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent(sampleType: event, badgeNumber: self.numberOfEventsReceivedWhileInBackgroundStore.value)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "NotificationTest", content: content, trigger: trigger)
        
        center.add(request, withCompletionHandler: { (error) in
            if (error != nil) {
                print("\(#function):\(error)")
            }
        })
    }
    
}

extension UNMutableNotificationContent {
    convenience init(sampleType: HKSample ,badgeNumber: Int = 0) {
        self.init()
        badge = badgeNumber as NSNumber?
        title = "StepCount updated"
        body = "StepCount"
        sound = UNNotificationSound.default()
    }
}
