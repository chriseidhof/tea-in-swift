//
//  AppState.swift
//  TodosFramework
//
//  Created by Chris Eidhof on 21.06.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import VirtualViews

struct Todo {
    var title: String
    var done: Bool
}

struct List {
    var title: String
    var items: [Todo]
}

public struct TodosApp {
    var lists: [List]
    var selectedListIndex: Int?
    
    public init() {
        lists = []
        selectedListIndex = nil
    }
}

extension List {
    var tableView: TableView<TodosApp.Message> {
        let cells: [TableViewCell<TodosApp.Message>] = items.enumerated().map { el in
            let (index, todo) = el
            return TableViewCell<TodosApp.Message>(text: todo.title, onSelect: TodosApp.Message.toggleDone(index: index), accessory: todo.done ? .checkmark: .none, onDelete: nil)
        }
        return TableView<TodosApp.Message>(items: cells)
    }
}

extension Array where Element == List {
    var tableViewController: ViewController<TodosApp.Message> {
        let cells: [TableViewCell<TodosApp.Message>] = zip(self, self.indices).map { (el) in
            let (item, index) = el
            return TableViewCell(text: item.title, onSelect: .select(listIndex: index), onDelete: .delete(listIndex: index))
        }
        return ViewController.tableViewController(TableView(items: cells))
    }
}

extension TodosApp: RootComponent {
    
    public enum Message {
        case back
        case select(listIndex: Int)
        case addList
        case addItem
        case createList(String?)
        case createItem(String?)
        case delete(listIndex: Int)
        case toggleDone(index: Int)
    }
    
    var selectedList: List? {
        get {
            guard let i = selectedListIndex else { return nil }
            return lists[i]
        }
        set {
            guard let i = selectedListIndex, let value = newValue else { return }
            lists[i] = value
        }
    }
    
    public var viewController: ViewController<Message> {
        let addList: BarButtonItem<Message> = BarButtonItem.system(.add, action: .addList)
        
        var viewControllers: [NavigationItem<Message>] = [
            NavigationItem(title: "Todos", leftBarButtonItem: nil, rightBarButtonItems: [addList], viewController: lists.tableViewController)
        ]
        if let list = selectedList {
            viewControllers.append(NavigationItem(title: list.title, rightBarButtonItems: [.system(.add, action: .addItem)], viewController: .tableViewController(list.tableView)))
        }
        return ViewController.navigationController(NavigationController(viewControllers: viewControllers, back: .back))
    }
    
    mutating public func send(_ msg: Message) -> [Command<Message>] {
        switch msg {
        case .addList:
            return [
                .modalTextAlert(title: "Add List",
                                accept: "OK",
                                cancel: "Cancel",
                                placeholder: "The title for your new list",
                                convert: { .createList($0) })]
        case .addItem:
            
            return [
                .modalTextAlert(title: "Add Item",
                                accept: "OK",
                                cancel: "Cancel",
                                placeholder: "The title for your new todo",
                                convert: { .createItem($0) })]
            
        case .createList(let title):
            guard let title = title else { return [] } // Pressed cancel
            lists.append(List(title: title, items: []))
            return []
        case .createItem(let title):
            guard let title = title else { return [] }
            selectedList?.items.append(Todo(title: title, done: false))
            return []
        case .select(listIndex: let index):
            selectedListIndex = index
            return []
        case .back:
            selectedListIndex = nil
            return []
        case .delete(listIndex: let index):
            lists.remove(at: index)
            return []
        case .toggleDone(index: let index):
            guard let i = selectedListIndex else { return [] }
            lists[i].items[index].done = !lists[i].items[index].done
            return []
        }
    }
    
    public var subscriptions: [Subscription<Message>] {
        return []
    }
}

extension TodosApp.Message: Equatable {
    public static func ==(lhs: TodosApp.Message, rhs: TodosApp.Message) -> Bool {
        switch (lhs, rhs) {
        case (.back, .back): return true
        case (.select(let l), .select(let r)): return l == r
        default: return false
        }
    }
}
