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

        eventsViewController.viewModel = EventsViewModel(store: eventsStore)
        //        secondViewController.viewModel = FillMemoryViewModel()

        // TODO: set up HealthKit background delivery
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
                print("Horray! \(value)")
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

}




