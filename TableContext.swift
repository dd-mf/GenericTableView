//
//  TableContext.swift
//  Created by J.Rodden
//

import UIKit

public struct TableContext
{
    public var indexPath: IndexPath
    public var tableView: UITableView
    
    public var viewController: UIViewController
    
    public init(_ indexPath: IndexPath,
                _ tableView: UITableView,
                _ viewController: UIViewController)
    {
        self.indexPath = indexPath
        self.tableView = tableView
        self.viewController = viewController
    }
    
    public init(_ indexPath: IndexPath,
                _ viewController: UITableViewController)
    {
        let tableView = viewController.tableView!
        self.init(indexPath, tableView, viewController)
    }
}

// MARK: -

public extension TableContext
{
    public var tableCell: UITableViewCell!
    { return tableView.cellForRow(at: indexPath) }
    
    public func deselectRow(animated: Bool)
    {
        tableView.deselectRow(at: indexPath, animated: animated)
    }
    
    public func pushViewController(_ vc: UIViewController, animated: Bool)
    {
        if let navigationController =
            viewController as? UINavigationController
                ?? viewController.navigationController
                ?? viewController.presentingViewController?.navigationController
        {
            navigationController.pushViewController(vc, animated: animated)
        }
    }
}
