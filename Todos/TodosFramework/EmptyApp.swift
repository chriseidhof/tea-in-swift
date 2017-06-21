//
//  AppState.swift
//  TodosFramework
//
//  Created by Chris Eidhof on 21.06.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import VirtualViews

public struct EmptyApp {
    
    public init() { }
}

extension EmptyApp: RootComponent {
    
    public enum Message { }
    
    public var viewController: ViewController<Message> {
        return .viewController(View<Message>.label(text: "Hello, world"))
    }
    
    mutating public func send(_: EmptyApp.Message) -> [Command<EmptyApp.Message>] {
        return []
    }
    
    
    public var subscriptions: [Subscription<Message>] {
        return []
    }
}

extension EmptyApp.Message: Equatable {
    public static func ==(lhs: EmptyApp.Message, rhs: EmptyApp.Message) -> Bool {
        // todo
        return false
    }
}
