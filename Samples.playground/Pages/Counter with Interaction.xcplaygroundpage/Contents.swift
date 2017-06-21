import UIKit
import TodosFramework
import VirtualViews

//: We'll re-use our previous state, but will add interaction to it.
struct Counter {
    var count: Int = 0
}

//: The `send` method and `Message` are still the same.
extension Counter: RootComponent {
    enum Message {
        case increment
        case decrement
    }
    
    mutating func send(_ msg: Message) -> [Command<Message>] {
        switch msg {
        case .decrement:
            count -= 1
        case .increment:
            count += 1
        }
        return []
    }
    
//: Now we add a button. This is one of the interesting things about TEA: the button does not have a callback, delegate or target/action pattern.
//: Instead, it has an associated message for onTap. Whenever the button is tapped, the `Driver` will automatically dispatch that method to the `send` method.
//: This makes it very easy to test two things in isolation: first of all, we can easily verify that `send(.increment)` actually increments the state. Also, we
//: can easily test that the button has an associated .increment action.
    var viewController: ViewController<Message> {
        return .viewController(.stackView(views: [
            .label(text: "Count: \(count)"),
            .button(text: "Increment", onTap: .increment)
            ])
    }
    
    var subscriptions: [Subscription<Message>] {
        return []
    }
}

//: The only way to change the state is through sending a message. Because the `Driver` will take care of updating the view hierarchy, it is not possible to forget to update your views when the state changes. This all happens automatically.

let driver = Driver(Counter(count: 0))
PlaygroundPage.current.liveView = driver.viewController.view

extension Counter.Message: Equatable {
    static func ==(lhs: Counter.Message, rhs: Counter.Message) -> Bool {
        switch (lhs, rhs) {
        case (.increment, .increment): return true
        case (.decrement, .decrement): return true
        default: return false
        }
    }
}
