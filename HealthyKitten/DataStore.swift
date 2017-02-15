//
//  DataStore.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 10/02/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import Foundation

protocol Storable {} // ?

protocol DataStore {
    
    associatedtype Element: Storable
    
    var value: Element { get set } // ?
    
    func addUpdateHandler(callback: @escaping (Self) -> ())
}

final class UserDefaultsDataStore<Element: PropertyListSerializable>: DataStore {
    init(key: String, defaultValue: Element) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    let key: String
    private let defaultValue: Element
    
    var value: Element {
        get {
            guard let plist = defaults.object(forKey: key) else {
                return defaultValue
            }
            guard let v = Element.init(propertyList: plist) else {
                preconditionFailure("Invalid property list: \(plist)")
            }
            return v
        }
        
        set {
            let plist = newValue.propertyListRepresentation()
            defaults.set(plist, forKey: key)
            for callback in updateHandlers {
                callback(self)
            }
        }
    }
    
    private let defaults = UserDefaults()
    private var updateHandlers: [(UserDefaultsDataStore<Element>) -> ()] = []

    func addUpdateHandler(callback: @escaping (UserDefaultsDataStore<Element>) -> ()) {
        updateHandlers.append(callback)
    }
}
