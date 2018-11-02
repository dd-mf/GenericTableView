//
//  StandardTableItem.swift
//  Created by J.Rodden
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

    var shouldHighlight: Bool { get }
    var accessoryType: UITableViewCell.AccessoryType { get }
    var selectionStyle: UITableViewCell.SelectionStyle { get }
    
    func handleSelection(_ context: TableContext)
    
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

    var shouldHighlight: Bool { return (selectionStyle != .none) }
    var accessoryType: UITableViewCell.AccessoryType { return .none }
    var selectionStyle: UITableViewCell.SelectionStyle { return .default }

    func configuredCell(for tableView: UITableView,
                        at indexPath: IndexPath) -> UITableViewCell
    {
        let identifier = cellType.identifier
        let cell = tableView.dequeueReusableCell(
            withIdentifier: identifier, for: indexPath)
        
        configure(cell, forUseAt: indexPath)
        
        return cell
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
    
    public convenience init(
        _ s1: String, _ s2: String? = nil)
    {
        self.init(); title = s1; detail = s2
    }
    
    public init(_ data: Data = Data())
    {
        self.data = data; super.init()
    }
    
    override open var description: String
    { return (data as NSDictionary).description }
    
    open func configure(_ cell: UITableViewCell,
                        forUseAt indexPath: IndexPath)
    {
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
        
        type(of: self).keyPaths.forEach()
        {
            if !skip(property: $0)
            {
                let keyPath = String(describing: $1)
                let newValue = value(forKeyPath: $0.rawValue)
                cell.setValue(newValue, forKeyPath: keyPath)
            }
        }
        
        configureBlock?(cell, indexPath)
    }

    // MARK: - Constants

    /// internally stored properties
    public enum Property: String
    {
        case extraData
        case ID, cellType
        case configureBlock
        case image, title, detail
        case titleColor, detailColor
        case accessoryType, accessoryView
        case attributedTitle, attributedDetail
        case selectionStyle, selectionCallback
    }
    
    /// map Property values to corresponding keyPath
    private static var keyPaths: [Property:String] =
    [
        .image : #keyPath(UITableViewCell._image),

        .title : #keyPath(UITableViewCell._text),
        .detail : #keyPath(UITableViewCell._detailText),
        
        .titleColor : #keyPath(UITableViewCell._textColor),
        .detailColor : #keyPath(UITableViewCell._detailTextColor),
        
        .accessoryType : #keyPath(UITableViewCell.accessoryType),
        .accessoryView : #keyPath(UITableViewCell.accessoryView),
        
        .selectionStyle : #keyPath(UITableViewCell.selectionStyle),
        
        .attributedTitle : #keyPath(UITableViewCell._attributedText),
        .attributedDetail : #keyPath(UITableViewCell._detailAttributedText),
    ]
    
    public typealias ConfigureBlock = (_: UITableViewCell, _: IndexPath) -> Void

    // MARK: - Internal
    
    private func skip(property: Property) -> Bool
    {
        switch property
        {   // either title or attributedTitle
        case .attributedTitle:  return title != nil
        case .title:    return attributedTitle != nil
            
            // either detail or attributedDetail
        case .attributedDetail: return detail != nil
        case .detail:   return attributedDetail != nil

        default: return false
        }
    }
    
    internal func set(_ property: Property,
                      to newValue: Any?, redraw: Bool = true)
    {
        if Thread.main == Thread.current
        {
            // update our data storage
            if newValue != nil
            {
                data[property] = newValue
            }
            else
            {
                data.removeValue(forKey: property)
            }
            
            // these lines check to see if self is currently
            // bound to a (currently visible) UITableViewCell
            if redraw,
                let target = type(of: self).keyPaths[property],
                (cell as? DefaultTableViewCell)?.tableItem === self
            {
                // self is currently bound to cell, so tell the cell
                // to update it's value for the associated keyPath
                cell?.setValue(newValue, forKeyPath:String(describing: target))
            }
        }
        else
        {
            OperationQueue.main.addOperation
            {
                [weak self] in self?.set(property, to: newValue)
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
    @objc open var accessoryType: UITableViewCell.AccessoryType
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
    
    /// the selection style to use for this tableItem
    @objc open var selectionStyle: UITableViewCell.SelectionStyle
    {
        // this needs to be stored as an Int, in order to work
        get { return UITableViewCell.SelectionStyle(
            rawValue: data[.selectionStyle] as? Int ??
            UITableViewCell.SelectionStyle.default.rawValue)!  }
        set { set(.selectionStyle, to: newValue.rawValue as Any) }
    }
    
    /// subclasses can override this to implement selection behavior
    open func handleSelection(_ context: TableContext) { handleSelectionCallback?(context) }
    
    /// (optional) selection behavior for this tableItem.
    public typealias SelectionCallback = (TableContext) -> Void
    public var handleSelectionCallback: SelectionCallback?
    {
        set { set(.selectionCallback, to: newValue, redraw: false) }
        get { return (data[.selectionCallback] as? SelectionCallback) }
    }
}

// MARK: -

public extension TableContext
{
    public func toggleCheckmark()
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
