//
//  PropertyListSerializable.swift
//  HealthyKitten
//
//  Created by Tatsuya Kaneko on 10/02/17.
//  Copyright © 2017 Tatsuya Kaneko. All rights reserved.
//

import Foundation
import UIKit

protocol PropertyListSerializable: Storable{
    init?(propertyList: Any)
    func propertyListRepresentation() -> Any
}

enum HKSample {
    case Sleep(receivedAt: Date,
               applicationState: UIApplicationState,
               payload: [String : Any])
    case StepCount(receivedAt: Date,
               applicationState: UIApplicationState,
               payload: [String : Any])
}

extension HKSample: CustomStringConvertible {
    public var description: String {
        switch self {
        case .Sleep(receivedAt: let receivedAt, applicationState: let applicationState, payload: let payload):
            return "Sleep: \(receivedAt) - \(applicationState) - \(payload)"
        case .StepCount(receivedAt: let receivedAt, applicationState: let applicationState, payload: let payload):
            return "StepCount: \(receivedAt) - \(applicationState) - \(payload)"
        }
    }
}

extension HKSample: PropertyListSerializable {
    init?(propertyList: Any){
        guard let dict = propertyList as? [String: Any],
              let type = dict["type"] as? String
        else {
            return nil
        }
        
        switch type {
            case "Sleep":
                guard let receivedAt = dict["receivedAt"] as? Date,
                      let applicationStatePropertyList = dict["applicationState"],
                      let applicationState = UIApplicationState(propertyList: applicationStatePropertyList),
                      let payload = dict["payload"] as? [String : Any]
                else{
                    return nil
                }
                self = .Sleep(receivedAt: receivedAt, applicationState: applicationState, payload: payload)
            case "StepCount":
                guard let receivedAt = dict["receivedAt"] as? Date,
                    let applicationStatePropertyList = dict["applicationState"],
                    let applicationState = UIApplicationState(propertyList: applicationStatePropertyList),
                    let payload = dict["payload"] as? [String : Any]
                    else{
                        return nil
                }
                self = .StepCount(receivedAt: receivedAt, applicationState: applicationState, payload: payload)
            default:
                fatalError("Unknown event type: \(type)")
        }
    }
    
    func propertyListRepresentation() -> Any {
        switch self {
        case .Sleep(receivedAt: let receivedAt, applicationState: let applicationState, payload: let payload):
            return [
                "type": "Sleep",
                "receivedAt": receivedAt,
                "applicationState": applicationState.propertyListRepresentation(),
                "payload": payload
            ]
        case .StepCount(receivedAt: let receivedAt, applicationState: let applicationState, payload: let payload):
            return [
                "type": "StepCount",
                "receivedAt": receivedAt,
                "applicationState": applicationState.propertyListRepresentation(),
                "payload": payload
            ]
        }
    }
}

extension UIApplicationState: PropertyListSerializable {
    init?(propertyList: Any) {
        guard let rawValue = propertyList as? Int else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
    
    func propertyListRepresentation() -> Any {
        return self.rawValue
    }
}

extension UIApplicationState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        }
    }
}

extension Int: PropertyListSerializable {
    init?(propertyList: Any) {
        guard let value = propertyList as? Int else {
            return nil
        }
        self = value
    }
    
    func propertyListRepresentation() -> Any {
        return self
    }
}

/// A wrapper for Array that conforms to PropertyListSerializable.
/// Elements must themselves conform to PropertyListSerializable.
///
/// This is a hack that is required because Swift 2.x doesn't support this:
///
///     extension Array: PropertyListSerializable where Element: PropertyListSerializable {
///         ...
///     }
///     // error: Extension of type 'Array' with constraints cannot have an inheritance clause
struct SerializableArray<Element: PropertyListSerializable> {
    var elements: [Element] = []
    
    init(_ elements: [Element]) {
        self.elements = elements
    }
}

extension SerializableArray: Collection {
    var startIndex: Int {
        return elements.startIndex
    }
    
    var endIndex: Int {
        return elements.endIndex
    }
    
    subscript(index: Int) -> Element {
        return elements[index]
    }
    
    func index(after i: Int) -> Int {
        guard i != endIndex else {fatalError("Cannnot increment endIndex") }
        return i + 1
    }
}

extension SerializableArray: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension SerializableArray: PropertyListSerializable {
    init?(propertyList: Any) {
        guard let plistElements = propertyList as? [Any] else {
            return nil
        }
        let deserializedElements = plistElements.flatMap { element in
            Element(propertyList: element)
        }
        self.init(deserializedElements)
    }
    
    func propertyListRepresentation() -> Any {
        return self.map { $0.propertyListRepresentation() }
    }
}
