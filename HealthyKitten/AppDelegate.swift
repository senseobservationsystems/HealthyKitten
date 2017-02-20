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

    let healthKitManager = HealthKitManager()
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
        healthKitManager.requestAuthorization { (success, error) in
            guard error == nil else {
                // Perform Proper Error Handling Here...
                print("\(#function):\(error)")
                abort()
            }
            self.healthKitManager.startObservingDailyStepCount() {
                (value, error) in
                guard error == nil else {
                    print("\(#function):\(error)")
                    abort()
                }
                
                guard value != nil else {
                    print("\(#function): value is nil")
                    abort()
                }
                
                self.onHKNewDailyStepCount(application, value: value!)
            }
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
    
    func onHKNewDailyStepCount(_ application: UIApplication, value: Double) {
        let payload = ["value": value]
        let event = HKSample.StepCount(receivedAt: Date(),
                                       applicationState: application.applicationState,
                                       payload: payload)
        self.eventsStore.value.elements.insert(event, at: 0)
        
        if application.applicationState != .active {
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
        
        print("Horray! \(payload)")
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
