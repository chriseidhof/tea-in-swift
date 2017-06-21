import UIKit

public struct StrongReferences {
	private var handlers: [Any] = []
	public mutating func append(_ obj: Any) {
		handlers.append(obj)
	}
	
	mutating func append(contentsOf other: [Any]) {
		handlers.append(contentsOf: other)
	}
}

class TargetAction: NSObject { // todo: removeTarget?
	var handle: () -> ()
	init(_ handle: @escaping () -> ()) {
		self.handle = handle
	}
	@objc func performAction(sender: UIButton) {
		handle()
	}
}

final class NCDelegate: NSObject, UINavigationControllerDelegate {
	var back: (() -> ())
	init(back: @escaping () -> ()) {
		self.back = back
	}
	
	func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		if operation == .pop {
			back()
		}
		return nil
	}
}

class TextfieldDelegate: NSObject, UITextFieldDelegate {
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}

let reusableCellIdentifier = "Cell"
class TableViewBacking<A>: NSObject, UITableViewDataSource, UITableViewDelegate {
	let cells: [TableViewCell<A>]
	let callback: ((A) -> ())?
	init(cells: [TableViewCell<A>], callback: ((A) -> ())? = nil) {
		self.cells = cells
		self.callback = callback
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cells.count
	}
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: reusableCellIdentifier, for: indexPath)
		cell.textLabel?.text = cells[indexPath.row].text
		return cell
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete, let action = cells[indexPath.row].onDelete {
			callback?(action)
		}
	}
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let value = cells[indexPath.row].onSelect {
			callback?(value)
		}
	}
}


final class SplitViewControllerDelegate: NSObject, UISplitViewControllerDelegate {
	var collapseSecondaryViewController: Bool
	init(collapseSecondaryViewController: Bool) {
		self.collapseSecondaryViewController = collapseSecondaryViewController
	}
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		return collapseSecondaryViewController
	}
}

extension BarButtonItem {
	func render(_ callback: @escaping (Message) -> (), viewController: UIViewController, change: inout UIBarButtonItem?) -> [Any] {
		switch self {
		case .builtin(let button):
			if change != button { change = button }
			return []
		case let .custom(text: text, action: action):
			let target = TargetAction { callback(action) }
			change = UIBarButtonItem(title: text, style: .plain, target: target, action: #selector(TargetAction.performAction(sender:)))
			return [target]
		case let .system(item, action: action):
			let target = TargetAction { callback(action) }
			change = UIBarButtonItem(barButtonSystemItem: item, target: target, action: #selector(TargetAction.performAction(sender:)))
			return [target]
			
		case .editButtonItem:
			change = viewController.editButtonItem
			return []
		}
	}
}


public struct Renderer<A> {
	public var strongReferences = StrongReferences()
	private let callback: (A) -> ()
	public init(callback: @escaping (A) -> ()) {
		self.callback = callback
	}
	
	private mutating func render(_ button: Button<A>, into b: UIButton) {
		b.removeTarget(nil, action: nil, for: .touchUpInside)
		if let action = button.onTap {
			let cb = self.callback
			let target = TargetAction { cb(action) }
			strongReferences.append(target)
			b.addTarget(target, action: #selector(TargetAction.performAction(sender:)), for: .touchUpInside)
		}
		
		b.setTitle(button.text, for: .normal)
		b.backgroundColor = .lightGray
	}
	
	private func render(label text: String, into l: UILabel) {
		l.text = text
		l.backgroundColor = .white
	}
	
	// this does *not* render the children
	private func render(_ stackView: StackView<A>, into result: UIStackView) {
		result.distribution = stackView.distribution
		result.axis = stackView.axis
		result.backgroundColor = stackView.backgroundColor
	}
	
	private mutating func render(_ textField: TextField<A>, into result: UITextField) {
		result.text = textField.text
		result.borderStyle = .roundedRect
		result.removeTarget(nil, action: nil, for: .editingChanged)
		if let onChange = textField.onChange {
			let cb = self.callback
			let target = TargetAction { [unowned result] in
				cb(onChange(result.text))
			}
			result.addTarget(target, action: #selector(TargetAction.performAction(sender:)), for: .editingChanged)
			strongReferences.append(target)
		}
		let delegate = TextfieldDelegate()
		result.delegate = delegate
		strongReferences.append(delegate)
	}
	
	private mutating func render(_ slider: Slider<A>, into result: UISlider) {
		result.minimumValue = 0
		result.maximumValue = slider.max
		result.value = slider.progress
		result.backgroundColor = .white
		result.removeTarget(nil, action: nil, for: .valueChanged)
		if let action = slider.onChange {
			let cb = self.callback
			let target = TargetAction { [unowned result] in
				cb(action(result.value))
			}
			result.addTarget(target, action: #selector(TargetAction.performAction(sender:)), for: .valueChanged)
			strongReferences.append(target)
		}
	}
	
	public mutating func render(_ tableView: TableView<A>, into result: UITableView) {
		// todo: don't re-set the delegate / ds or reload the data unless necessary
		let backing = TableViewBacking(cells: tableView.items, callback: self.callback)
		result.register(UITableViewCell.self, forCellReuseIdentifier: reusableCellIdentifier) // todo: don't register if we've already registered.
		result.delegate = backing
		result.dataSource = backing
		strongReferences.append(backing)
		result.reloadData() // todo use diffing
	}
	
	public mutating func render(view: View<A>) -> UIView {
		switch view {
		case let ._button(button):
			let b = UIButton()
			render(button, into: b)
			return b
		case let .label(text: text):
			let l = UILabel()
			render(label: text, into: l)
			return l
		case let ._stackView(stackView):
			let views = stackView.views.map { render(view: $0) }
			let result = UIStackView(arrangedSubviews: views)
			render(stackView, into: result)
			return result
		case let ._textfield(textField):
			let result = UITextField()
			render(textField, into: result)
			return result
		case let .imageView(image):
			return UIImageView(image: image)
		case let ._slider(slider):
			let result = UISlider()
			render(slider, into: result)
			return result
		case let .tableView(tableView):
			let result = UITableView(frame: .zero, style: .plain)
			render(tableView, into: result)
			return result
		}
	}
	
	public mutating func update(view: View<A>, into existing: UIView) -> UIView {
		switch view {
		case let ._button(button):
			guard let b = existing as? UIButton else {
				return render(view: view)
			}
			render(button, into: b)
			return b
		case let .label(text: text):
			guard let l = existing as? UILabel else {
				return render(view: view)
			}
			render(label: text, into: l)
			return l
		case let ._stackView(stackView):
			guard let result = existing as? UIStackView, result.arrangedSubviews.count == stackView.views.count else {
				return render(view: view)
			}
			for (index, existingSubview) in result.arrangedSubviews.enumerated() {
				let sub = stackView.views[index]
				let new = update(view: sub, into: existingSubview)
				if new !== existingSubview {
					result.removeArrangedSubview(existingSubview)
					result.insertArrangedSubview(new, at: Int(index))
				}
			}
			render(stackView, into: result)
			return result
		case let ._textfield(textField):
			guard let result = existing as? UITextField else {
				return render(view: view)
			}
			render(textField, into: result)
			return result
		case let ._slider(slider):
			guard let result = existing as? UISlider else {
				return render(view: view)
			}
			render(slider, into: result)
			return result
		case let .imageView(image):
			guard let result = existing as? UIImageView else {
				return render(view: view)
			}
			result.image = image
			return result
		case let .tableView(tableView):
			guard let result = existing as? UITableView else {
				return render(view: view)
			}
			render(tableView, into: result)
			return result
		}
	}
	
}


extension SplitViewController {
	func render(callback: @escaping (Message) -> (), viewController vc: UISplitViewController) -> StrongReferences {
		if vc.viewControllers == [] {
			vc.viewControllers = [UINavigationController(), UIViewController()]
		}
		let nc = vc.viewControllers[0] as! UINavigationController
		var strongReferences: StrongReferences
		if vc.viewControllers.count == 1 {
			var copy = left(vc.displayModeButtonItem)
			if !collapseSecondaryViewController {
				copy.viewControllers.append(contentsOf: right(vc.displayModeButtonItem).viewControllers)
				copy.back = popDetail
			}
			strongReferences = copy.render(callback: callback, viewController: nc)
		} else {
			strongReferences = left(vc.displayModeButtonItem).render(callback: callback, viewController: nc)
			let detail: ViewController<Message> = .navigationController(right(vc.displayModeButtonItem))
			strongReferences.append(detail.render(callback: callback, change: &vc.viewControllers[1]))
		}
		let delegate = SplitViewControllerDelegate(collapseSecondaryViewController: collapseSecondaryViewController)
		vc.delegate = delegate
		vc.preferredDisplayMode = .allVisible
		strongReferences.append(delegate)
		return strongReferences
		
	}
}

extension ViewController {
	public func render(callback: @escaping (Message) -> (), change: inout UIViewController) -> StrongReferences {
		switch self {
		case let .navigationController(newNC):
			var n: UINavigationController! = change as? UINavigationController
			if n == nil {
				n = UINavigationController()
				change = n
			}
			
			return newNC.render(callback: callback, viewController: n)
		case let .tableViewController(view):
			var t: UITableViewController! = change as? UITableViewController
			if t == nil {
				t = UITableViewController()
				change = t
			}
			var r = Renderer(callback: callback)
			r.render(view, into: t.tableView)
			return r.strongReferences
		case  let .viewController(view):
			var r = Renderer(callback: callback)
			let newView = r.update(view: view, into: change.view)
			if newView !== change.view {
				change.view = newView
			}
			return r.strongReferences
		case .splitViewController(let newSVC, let modal):
			var s: UISplitViewController! = change as? UISplitViewController
			if s == nil {
				s = UISplitViewController()
				change = s
			}
			var strongReferences = newSVC.render(callback: callback, viewController: s)
			if let modal = modal {
				if var v = s.presentedViewController {
					strongReferences.append(modal.viewController.render(callback: callback, change: &v))
					assert(v == s.presentedViewController)
				} else {
					var vc = UIViewController()
					strongReferences.append(modal.viewController.render(callback: callback, change: &vc))
					vc.modalPresentationStyle = modal.presentationStyle
					s.present(vc, animated: true, completion: nil)
				}
			} else {
				s.presentedViewController?.dismiss(animated: true, completion: nil)
			}
			return strongReferences
		}
	}
}



extension NavigationItem {
	func render(callback: @escaping (Message) -> (), viewController: inout UIViewController) -> StrongReferences {
		var strongReferences = self.viewController.render(callback: callback, change: &viewController)
		let ni = viewController.navigationItem
		strongReferences.append(leftBarButtonItem?.render(callback, viewController: viewController, change: &ni.leftBarButtonItem) ?? [])
		ni.leftItemsSupplementBackButton = leftItemsSupplementsBackButton
		ni.title = title
		var rightBarButtonItems: [UIBarButtonItem] = []
		for button in self.rightBarButtonItems {
			var result: UIBarButtonItem? = nil
			strongReferences.append(contentsOf: button.render(callback, viewController: viewController, change: &result))
			if let r = result {
				rightBarButtonItems.append(r)
			}
		}
		ni.rightBarButtonItems = rightBarButtonItems
		return strongReferences
	}
}

extension NavigationController {
	func render(callback: @escaping (Message) -> (), viewController nc: UINavigationController) -> StrongReferences {
		var strongReferences = StrongReferences()
		if let back = back {
			let delegate = NCDelegate {
				callback(back)
			}
			nc.delegate = delegate
			strongReferences.append(delegate)
		}
		let diffN = viewControllers.count - nc.viewControllers.count
		if diffN < 0 {
			nc.viewControllers.removeLast(diffN)
		}
		for (v, index) in zip(viewControllers, nc.viewControllers.indices) {
			strongReferences.append(v.render(callback: callback, viewController: &nc.viewControllers[index]))
		}
		
		
		if diffN > 0 {
			for v in viewControllers.last(diffN) {
				var vc = UIViewController()
				strongReferences.append(v.render(callback: callback, viewController: &vc))
				nc.pushViewController(vc, animated: true)
			}
		}
		return strongReferences
		
	}
}

extension Array {
	func last(_ n: Int) -> ArraySlice<Element> {
		return self[endIndex-n..<endIndex]
	}
}
