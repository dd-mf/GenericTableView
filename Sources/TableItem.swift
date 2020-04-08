//
//  StandardTableItem.swift
//  Created by J.Rodden
//  Copyright © 2018 DD/MF & Associates. All rights reserved.
//

import UIKit
import Foundation

/// The "viewModel" protocol for binding data to a cell, and responding
/// to interactions with that cell (thereby providing that functionality
/// for the UITableViewDelegate and UITableViewDataSource)
public protocol TableItem: class
{
    var ID: String? { get }
    
    typealias Cell = UITableViewCell
    var cellType: Cell.Type { get }
    static var cellType: Cell.Type { get }

    var canEdit: Bool { get }
    typealias EditingStyle =
        UITableViewCell.EditingStyle
    var editingStyle: EditingStyle { get }
    
    var shouldHighlight: Bool { get }
    
    typealias AccessoryType =
        UITableViewCell.AccessoryType
    var accessoryType: AccessoryType { get }
    
    typealias SelectionStyle =
        UITableViewCell.SelectionStyle
    var selectionStyle: SelectionStyle { get }
    
    var indentationLevel: Int { get }
    
    typealias Context = TableContext
    func handleSelection(_ context: Context)
    
    /// configure a specific call to display this item's data
    func configure(_ cell: UITableViewCell, forUseAt: IndexPath)
}

// MARK: -

public extension TableItem
{
    var ID: String? { return nil }

    typealias DefaultCellType = DefaultTableViewCell
    var cellType: Cell.Type { return type(of: self).cellType }
    static var cellType: Cell.Type { return DefaultCellType.self }

    var canEdit: Bool { return editingStyle != .none }
    var editingStyle: EditingStyle { return .none }

    var shouldHighlight: Bool
    { return (selectionStyle != .none) }
    
    var accessoryType: AccessoryType { return .none }
    var selectionStyle: SelectionStyle { return .default }

    var indentationLevel: Int { return 0 }

    func handleSelection(_ context: Context) { }

    func configuredCell(for tableView: UITableView,
                        at indexPath: IndexPath) -> UITableViewCell
    {
        let identifier = cellType.identifier
        let cell = tableView.dequeueReusableCell(
            withIdentifier: identifier, for: indexPath)
        
        configure(cell, forUseAt: indexPath)
        
        return cell
    }

    // use this method to ensure self is "bound"
    // to a (currently visible) UITableViewCell
    // and update that cell's keyPaths if so
    func setValue(of cell: UITableViewCell?,
                keyPath: String, to newValue: Any?)
    {
        guard let cell = cell as? BaseTableViewCell,
            cell.tableItem === self else { return }

        if cell.responds(to: NSSelectorFromString(keyPath))
        {
            //print("setValue(of:keyPath: \(keyPath)" +
            //    " to: \(String(describing: newValue))")
            cell.setValue(newValue, forKeyPath: keyPath)
        }
    }
}

// MARK: -

public func StandardTableItems(_ data:
    [StandardTableItem.Data]) -> [TableItem]
{
    return data.map({ StandardTableItem($0) })
}

/// This is not a model class! It is a model "wrapper" or "viewModel" (or cellController)
/// which takes on the role of binding the data (and optionally caching it) to a cell,
/// and responding to interactions  with that cell, providing that functionality for the
/// UITableViewDelegate and UITableViewDataSource
open class StandardTableItem : NSObject, TableItem
{
    public weak var cell: UITableViewCell?
    
    internal var data: Data
    public typealias Data = [Property:Any]

    open class var cellType: Cell.Type
    { return DefaultCellType.self }
    
    open var cellType: Cell.Type
    {
        get { return data[.cellType] as?
            Cell.Type ?? type(of: self).cellType  }
        set { set(.cellType, to: newValue as Any) }
    }
    
    // MARK:
    
    public init(_ data: Data = Data())
    {
        self.data = data; super.init()
    }
    
    public convenience init(
        _ s1: String, _ s2: String? = nil)
    {
        self.init(); title = s1; detail = s2
    }
    
    override open var description: String
    { return (data as NSDictionary).description }

    // MARK: - Constants

    /// internally stored properties
    public enum Property: String, CaseIterable
    {
        case extraData
        case editingStyle
        case ID, cellType
        case configureBlock
        case image, title, detail
        case titleColor, detailColor
        case accessoryType, accessoryView
        case attributedTitle, attributedDetail
        case selectionStyle, selectionCallback
        
        var keyPath: String
        {
            return type(of: self).mapping[self] ?? rawValue
        }
        
        private static let mapping: [Property:String] =
        [
        .image : #keyPath(UITableViewCell._image),
        
        .title : #keyPath(UITableViewCell._text),
        .detail : #keyPath(UITableViewCell._detailText),
        
        .titleColor : #keyPath(UITableViewCell._textColor),
        .detailColor : #keyPath(UITableViewCell._detailTextColor),
        
        .attributedTitle : #keyPath(UITableViewCell._attributedText),
        .attributedDetail : #keyPath(UITableViewCell._detailAttributedText),
        ]
    }
    
    public typealias ConfigureBlock = (_: StandardTableItem, _: IndexPath) -> Void

    // MARK: - Configuration
    
    private func skip(property: Property) -> Bool
    {
        let skip: [ Property : ()->Bool ] =
        [   // either title or attributedTitle
            .attributedTitle:  { return self.title != nil },
            .title:  { return self.attributedTitle != nil },
            
            // either detail or attributedDetail
            .attributedDetail: { return self.detail != nil },
            .detail: { return self.attributedDetail != nil },
        ]
        
        return skip[property]?() ?? false
    }
    
    internal func set(_ property: Property,
                      to newValue: Any?, redraw: Bool = true)
    {
        if Thread.main != Thread.current
        {
            OperationQueue.main.addOperation
            {
                [weak self] in self?.set(property, to: newValue)
            }
        }
        else
        {
            // update our data storage
            if let newValue = newValue
            {
                data[property] = newValue
            }
            else
            {
                data.removeValue(forKey: property)
            }
            
            if redraw
            {   // if self is currently bound to a (visible) cell,
                // set value for the associated keyPath to newValue
                setValue(of: cell, keyPath: property.keyPath, to: newValue)
            }
        }
    }
    
    open func configure(_ cell: UITableViewCell,
                        forUseAt indexPath: IndexPath)
    {
        defer
        {
            configureBlock?(self, indexPath)
        }
        
        if let cell = cell as? BaseTableViewCell
        {
            defer
            {   // bind cell & viewModel
                self.cell = cell
                
                var theCell = cell
                theCell.tableItem = self
            }
            // ...but first detach from previous
            if let previousTableItem =
                cell.tableItem as? StandardTableItem
            {
                previousTableItem.cell = nil
            }
        }
        
        Property.allCases.forEach()
        {
            let keyPath = $0.keyPath
            if !skip(property: $0), cell.responds(
                to: NSSelectorFromString(keyPath))
            {
                let newValue = value(forKeyPath: $0.rawValue)
                cell.setValue(newValue, forKeyPath: keyPath)
            }
        }
    }

    // MARK: - Accessors

    /// optional identifier for client use
    @objc public var ID: String?
    {
        get { return data[.ID] as? String }
        set { set(.ID, to: newValue, redraw: false) }
    }
    
    /// the UIImage to use for this tableItem's imageView
    @objc open var image: UIImage?
    {
        get { return data[.image] as? UIImage }
        set { set(.image, to: newValue as Any?) }
    }
    
    // MARK:

    /// the String to use for this tableItem's title
    @objc open var title : String?
    {
        get { return data[.title] as? String }
        set
        {
            if newValue != nil
            {
                set(.attributedTitle,
                    to: nil, redraw: false)
            }
            set(.title, to: newValue as Any?)
        }
    }
    
    /// the String to use for this tableItem's detailText
    @objc open var detail : String?
    {
        get { return data[.detail] as? String }
        set
        {
            if newValue != nil
            {
                set(.attributedDetail,
                    to: nil, redraw: false)
            }
            set(.detail, to: newValue as Any?)
        }
    }
    
    /// the color to use for this tableItem's title
    @objc open var titleColor : UIColor?
    {
        get { return data[.titleColor] as? UIColor }
        set { set(.titleColor, to: newValue as Any?) }
    }
    
    /// the color to use for this tableItem's detailText
    @objc open var detailColor : UIColor?
    {
        get { return data[.detailColor] as? UIColor }
        set { set(.detailColor, to: newValue as Any?) }
    }
    
    /// the attributedString to use for this tableItem's title
    @objc open var attributedTitle : NSAttributedString?
    {
        set
        {
            if newValue != nil
            {
                set(.title, to: nil, redraw: false)
            }
            set(.attributedTitle, to: newValue as Any?)
        }
        get { return data[.attributedTitle] as? NSAttributedString }
    }
    
    /// the attributedString to use for this tableItem's detailText
    @objc open var attributedDetail : NSAttributedString?
    {
        set
        {
            if newValue != nil
            {
                set(.detail, to: nil, redraw: false)
            }
            set(.attributedDetail, to: newValue as Any?)
        }
        get { return data[.attributedDetail] as? NSAttributedString }
    }

    // MARK:
    
    /// the accessoryType to use for this tableItem
    @objc open var accessoryType: AccessoryType
    {
        // this needs to be stored as an Int, in order to work
        get { return UITableViewCell.AccessoryType(
            rawValue: data[.accessoryType] as? Int ??
                UITableViewCell.AccessoryType.none.rawValue)!  }
        set { set(.accessoryType, to: newValue.rawValue as Any) }
    }
    
    /// the accessoryView to use for this tableItem
    @objc open var accessoryView: UIView?
    {
        get { return data[.accessoryView] as? UIView }
        set { set(.accessoryView, to: newValue as Any?) }
    }
    
    // MARK:

    /// (optional) closure block called w/in
    /// tableView:cellForRowAtIndexPath:
    /// (note that it is called multiple times
    /// for any given cell instance so be very
    /// careful if adding subviews here)
    @objc open var configureBlock: ConfigureBlock?
    {
        get { return data[.configureBlock] as? ConfigureBlock }
        set { set(.configureBlock, to: newValue, redraw: false) }
    }
    
    // MARK:
    
    @objc open var editingStyle: EditingStyle
    {
        set { set(.editingStyle, to: newValue, redraw: false) }
        get { return (data[.editingStyle] as? EditingStyle) ?? .none }
    }

    // MARK:
    
    /// the selection style to use for this tableItem
    @objc open var selectionStyle: SelectionStyle
    {
        // this needs to be stored as an Int, in order to work
        get { return UITableViewCell.SelectionStyle(
            rawValue: data[.selectionStyle] as? Int ??
            UITableViewCell.SelectionStyle.default.rawValue)!  }
        set { set(.selectionStyle, to: newValue.rawValue as Any) }
    }
    
    /// subclasses can override this to implement selection behavior
    open func handleSelection(_ context: Context) { selectionCallback?(context) }
    
    /// (optional) selection behavior for this tableItem.
    public typealias SelectionCallback = (Context) -> Void
    public var selectionCallback: SelectionCallback?
    {
        set { set(.selectionCallback, to: newValue, redraw: false) }
        get { return (data[.selectionCallback] as? SelectionCallback) }
    }
}

// MARK: -

public extension TableContext
{
    func toggleCheckmark()
    {
        guard let tableItem =
            tableCell?.tableItem as? StandardTableItem
            else { tableCell?.toggleCheckmark(); return }

        let isChecked = tableItem.accessoryType == .checkmark
        
        if isChecked || tableItem.accessoryType == .none
        {
            tableItem.accessoryType = isChecked ? .none : .checkmark
        }
    }
}
