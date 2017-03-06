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

    static let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount)!
    static let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    
    let healthKitManager = HealthKitManager(typesToRead: [stepCount, sleep])
    /// Stores the sequence of "Health kit sample events" our app received. Possible event types are:
    /// - StepCount
    /// - Sleep
    let eventsStore = UserDefaultsDataStore<SerializableArray<Event>>(key: "HealthKitSampleEvents", defaultValue: [])
    
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
        let event = Event.AppEvent(receivedAt: Date(), appEvent: "App in focus")
        self.eventsStore.value.elements.insert(event, at: 0)
        
        numberOfEventsReceivedWhileInBackgroundStore.value = 0
        application.applicationIconBadgeNumber = numberOfEventsReceivedWhileInBackgroundStore.value
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        let event = Event.AppEvent(receivedAt: Date(), appEvent: "App did enter background")
        self.eventsStore.value.elements.insert(event, at: 0)
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        print("\(#function)")
    }

    
    func onHKAuthoriazationGranted(){
        self.setStepCountQuery()
        self.setSleepQuery()
    }
    
    func setStepCountQuery(){
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let onNewHKDailyStepCount = {(value: Double?) in
            let payload = ["value": value]
            let applicationState = UIApplication.shared.applicationState
            let event = Event.HKEvent(sampleType: "StepCount",
                                      receivedAt: Date(),
                                      applicationState: applicationState,
                                      payload: payload)
            self.eventsStore.value.elements.insert(event, at: 0)
            
            if applicationState != .active {
                self.sendNotification(event: event)
            }
        }
        
        healthKitManager.startBackgroundDelivery(forSampleType: stepCountType,
                                                 frequency: .immediate) {
            error in
            
            // The action that should be executed on background delivery
            let query = QueryHelper.getStepCountQuery(for: .daily, handler: onNewHKDailyStepCount)
            self.healthKitManager.healthStore.execute(query)
        }
    }
    
    func setSleepQuery(){
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }
        
        let onNewHKDailySleep = { (value: Double?) in
            let payload = ["value": value]
            let applicationState = UIApplication.shared.applicationState
            let event = Event.HKEvent(sampleType: "Sleep",
                                      receivedAt: Date(),
                                      applicationState: applicationState,
                                      payload: payload)
            self.eventsStore.value.elements.insert(event, at: 0)
            
            if applicationState != .active {
                self.sendNotification(event: event)
            }
        }

        healthKitManager.startBackgroundDelivery(forSampleType: sleepType,
                                                 frequency: .immediate) {
            error in
                                                    
            // The action that should be executed on background delivery
            let query = QueryHelper.getSleepQuery(for: .daily, handler: onNewHKDailySleep)
            self.healthKitManager.healthStore.execute(query)
        }
    }
    
    func sendNotification(event: Event){
        self.numberOfEventsReceivedWhileInBackgroundStore.value += 1
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent(event: event, badgeNumber: self.numberOfEventsReceivedWhileInBackgroundStore.value)
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
    convenience init(event: Event ,badgeNumber: Int = 0) {
        self.init()
        badge = badgeNumber as NSNumber?
        let eventDict = event.propertyListRepresentation() as! [String : Any]
        title = "\(eventDict["sampleType"]) updated"
        body = "\(event.description)"
        sound = UNNotificationSound.default()
    }
}
