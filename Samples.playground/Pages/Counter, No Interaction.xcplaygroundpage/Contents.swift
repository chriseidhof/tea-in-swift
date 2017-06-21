import UIKit
import TodosFramework
import VirtualViews
import PlaygroundSupport

//: This is one of the simplest apps we could write in the Elm architecture. We'll start by defining our state struct:
struct Counter {
    var count: Int = 0
}

//: Now we're ready to make it conform to `RootComponent`. The Elm architecture works by sending messages to the state. The state then interprets these messages, and finally renders itself into a shadow view hierarchy.

extension Counter: RootComponent {
    // In this case, we only support two kinds of messages, increment and decrement
    enum Message {
        case increment
        case decrement
    }
    
    //: Messages in TEA are very similar to messages in OO. When an object receives a message, it'll mutate its internal state. We'll ignore the `Command` array for now, and just return an empty array.
    mutating func send(_ msg: Message) -> [Command<Message>] {
        switch msg {
        case .decrement:
            count -= 1
        case .increment:
            count += 1
        }
        return []
    }
    
    //: Our view controller consists of a single label with the current count
    var viewController: VC<Message> {
        return .viewController(.label(text: "Count: \(count)"))
    }
    
    //: We will look into subscriptions later.
    var subscriptions: [Subscription<Message>] {
        return []
    }
}

//: To render our view controller, we create a `Driver` instance. This object takes an initial state, and it allows us to get the view controller out (of type `UIViewController`):
let driver = Driver(Counter(count: 0))
driver.viewController.view

//: We can also send actions to the driver. This will dispatch the action through the `send` method. Then it re-renders the virtual view hierarchy, and updates the original view:
driver.send(action: .increment)
driver.viewController.view

extension Counter.Message: Equatable {
    static func ==(lhs: Counter.Message, rhs: Counter.Message) -> Bool {
        switch (lhs, rhs) {
        case (.increment, .increment): return true
        case (.decrement, .decrement): return true
        default: return false
        }
    }
}

//: TODO: this doesn't work on my current Xcode, but will probably work in the future again:
//: `PlaygroundPage.current.liveView = driver.viewController`
