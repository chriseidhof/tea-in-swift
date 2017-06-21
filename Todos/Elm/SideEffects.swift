//
//  SideEffects.swift
//  Recordings
//
//  Created by Chris Eidhof on 09.06.17.
//  Copyright © 2017 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
//

import UIKit

extension Player {
	public enum Command {
		case togglePlay
		case seek(to: TimeInterval)
	}
	
	public func apply(command: Command) {
		switch command {
		case .togglePlay: togglePlay()
		case .seek(let position): setProgress(position)
		}
	}
}

public enum Subscription<A> {
	case playProgress(player: Player, handle: (TimeInterval?) -> A)
	case recordProgress(recorder: Recorder, handle: (TimeInterval?) -> A)
	case storeChanged(handle: (Folder) -> A)
}

extension Subscription {
	public func map<B>(_ f: @escaping (A) -> B) -> Subscription<B> {
		switch self {
		case let .playProgress(player: player, handle: handle):
			return .playProgress(player: player, handle: { f(handle($0)) })
		case let .recordProgress(recorder: recorder, handle: handle):
			return .recordProgress(recorder: recorder, handle: { f(handle($0)) })
		case let .storeChanged(handle):
			return .storeChanged(handle: { f(handle($0)) })
		}
	}
}

public enum Command<A> {
	// Player
	case load(recording: Recording, available: (Player?) -> A)
	case player(Player, command: Player.Command)
	
	// Recorder
	case createRecorder(available: (Recorder?) -> A)
	case stop(Recorder)
	
	// Model
	case saveRecording(name: String, folder: Folder, file: URL)
	case createFolder(name: String, in: Folder)
	case delete(Item) // todo should probably be more specific than "Item"
	case changeName(Recording, String)
	
	// ViewControllers
	case modalTextAlert(title: String, accept: String, cancel: String, placeholder: String, convert: (String?) -> A)
	case modalAlert(title: String, accept: String)
	
	// Networking
	case request(URLRequest, available: (Data?) -> A)
	
	public func map<B>(_ f: @escaping (A) -> B) -> Command<B> {
		switch self {
		case let .load(recording, available):
			return .load(recording: recording, available: { player in
				f(available(player))
			})
		case let .player(player, command: command):
			return .player(player, command: command)
		case let .createRecorder(available):
			return .createRecorder(available: { f(available($0)) })
		case let .stop(r):
			return .stop(r)
		case let .saveRecording(name, folder, file):
			return .saveRecording(name: name, folder: folder, file: file)
		case let .createFolder(name, f):
			return .createFolder(name: name, in: f)
		case let .delete(item) :
			return .delete(item)
		case let .changeName(recording, str):
			return .changeName(recording, str)
		case let .modalTextAlert(title, accept, cancel, placeholder, convert):
			return .modalTextAlert(title: title, accept: accept, cancel: cancel, placeholder: placeholder, convert: { f(convert($0)) })
		case let .modalAlert(title: title, accept: accept):
			return .modalAlert(title: title, accept: accept)
		case let .request(request, available):
			return .request(request, available: { result in f(available(result))})
		}
	}
}

extension Command {
	func interpret(viewController: UIViewController!, callback: @escaping (A) -> ()) {
		switch self {
		case let .load(recording: r, available: f):
			let url = Store.shared.fileURL(for: r)
			let player = Player(url: url)
			callback(f(player))
		case let .player(player, command: command):
			player.apply(command: command)
		case let .modalTextAlert(title: title, accept: accept, cancel: cancel, placeholder: placeholder, convert: convert):
			viewController.modalTextAlert(title: title, accept: accept, cancel: cancel, placeholder: placeholder, callback: { str in
				callback(convert(str))
			})
		case let .modalAlert(title: title, accept: accept):
			let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: accept, style: .default, handler: nil))
			let vc: UIViewController = viewController.presentedViewController ?? viewController
			vc.present(alert, animated: true, completion: nil)
		case let .saveRecording(name, folder, url):
			let recording = Recording(name: name, uuid: UUID().uuidString)
			let destination = Store.shared.fileURL(for: recording)
			try! FileManager.default.copyItem(at: url, to: destination)
			Store.shared.add(.right(recording), to: folder)
		case let .stop(recorder):
			recorder.stop()
		case let .delete(item):
			Store.shared.delete(item)
		case let .createFolder(name, parent):
			let newFolder = Folder(name: name, uuid: UUID().uuidString)
			Store.shared.add(.left(newFolder), to: parent)
		case let .createRecorder(available: available):
			callback(available(Recorder(url: Store.shared.tempURL())))
		case let .changeName(recording, name):
			Store.shared.changeName(.right(recording), to: name)
		case let .request(request, available: available):
			URLSession.shared.dataTask(with: request) { (data, response, error) in
				callback(available(data))
			}.resume()
		}
	}
}

final class SubscriptionManager<Message> {
	var callback: (Message) -> ()
	var storeObservers: [Any] = []
	
	init(_ callback: @escaping (Message) -> ()) {
		self.callback = callback
	}
	
	func update(subscriptions: [Subscription<Message>]) {
		// Todo: here we should reuse existing observers, if possible?
		var newStoreObservers: [Any] = []
		for subscription in subscriptions {
			switch subscription {
			case .playProgress(let p, let f):
				p.update = { [weak self] position in self?.callback(f(position)) }
			case .recordProgress(recorder: let r, handle: let f):
				r.update = { [weak self] position in self?.callback(f(position)) }
			case .storeChanged(let handle):
				newStoreObservers.append(NotificationCenter.default.addObserver(forName: Store.ChangedNotification, object: nil, queue: nil) { [weak self] notification in
					self?.callback(handle(notification.object as! Folder))
				})
			}
		}
		for s in storeObservers {
			NotificationCenter.default.removeObserver(s)
		}
		storeObservers = newStoreObservers
	}
}

