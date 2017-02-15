//
//  EventsViewModel.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 15/02/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import Foundation

protocol Observable {
    func addObserver(callback: @escaping (Self) -> ())
    func notifyObservers()
}

final class EventsViewModel {
    
    init(store: UserDefaultsDataStore<SerializableArray<HKSample>>) {
        eventsStore = store
        eventsStore.addUpdateHandler { [weak self] store in
            guard let `self` = self else { // what is `self`?
                return
            }
            self.notifyObservers()
        }
    }

    var eventsStore: UserDefaultsDataStore<SerializableArray<HKSample>>
    var events: [HKSample] { return eventsStore.value.elements }
    
    var emptyStateViewHidden: Bool { return !eventsStore.value.isEmpty }
    var hasContentViewHidden: Bool { return eventsStore.value.isEmpty }
    var clearButtonEnabled: Bool { return !eventsStore.value.isEmpty }
    var exportButtonEnabled: Bool { return !eventsStore.value.isEmpty }
    
    func deleteAllData() {
        eventsStore.value = []
    }

    fileprivate var observers: [(EventsViewModel) -> ()] = []
    
}

extension EventsViewModel: Observable {
    func addObserver(callback: @escaping (EventsViewModel) -> ()) {
        observers.append(callback)
    }
    
    func notifyObservers() {
        for callback in observers {
            callback(self)
        }
    }
}
