import UIKit

public protocol RootComponent {
	associatedtype Message
	mutating func send(_: Message) -> [Command<Message>]
	var subscriptions: [Subscription<Message>] { get }
	var viewController: ViewController<Message> { get }
}

final public class Driver<Model> where Model: RootComponent {
	private var model: Model
	private var strongReferences: StrongReferences = StrongReferences()
	private var subscriptions: SubscriptionManager<Model.Message>!
	public private(set) var viewController: UIViewController = UIViewController()
	
	public init(_ initial: Model, commands: [Command<Model.Message>] = []) {
		model = initial
		strongReferences = model.viewController.render(callback: self.asyncSend, change: &viewController)
		subscriptions = SubscriptionManager(self.asyncSend)
		subscriptions?.update(subscriptions: model.subscriptions)
		for command in commands {
			interpret(command: command)
		}
	}
		
	public func send(action: Model.Message) { // todo this should probably be in a serial queue
		let commands = model.send(action)
		refresh()
		for command in commands {
			interpret(command: command)
		}
	}
	
	func asyncSend(action: Model.Message) {
		DispatchQueue.main.async {
			self.send(action: action)
		}
	}
	
	func interpret(command: Command<Model.Message>) {
		command.interpret(viewController: viewController, callback: self.asyncSend)
	}
	
	func refresh() {
		subscriptions?.update(subscriptions: model.subscriptions)
		strongReferences = model.viewController.render(callback: self.asyncSend, change: &viewController)
	}	
}
