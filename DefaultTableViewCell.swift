//
//  DefaultTableViewCell.swift
//  Created by J.Rodden
//

import UIKit

public protocol TableItemCell
{
    var tableItem: TableItem? { get set }
}

// MARK: -

extension TableItemCell
{
    public var tableItem: TableItem?
    {
        get { return nil }
        set { /* do nothing */ }
    }
}

// MARK: -

#if swift(>=4.2)
#else
extension UIActivityIndicatorView
{
    convenience init(style: Style)
    { self.init(activityIndicatorStyle: style) }
}
#endif

// MARK: -

/********************************************************
 To use a custom tableViewCell, you should override these
 properties and either retun nil, or return the analogous
 items w/in your custom cell. They are automatically set to
 the model's title, detail, and image w/in the tableItem's
 configure(_: UITableViewCell, forUseAt: IndexPath) method.
 
public extension UITableViewCell
{
    override var textLabel: UILabel? { return nil }
    override var detailTextLabel: UILabel? { return nil }
    override var imageView: UIImageView? { return nil }
}*/

public typealias DefaultTableViewCell = SubtitledTableViewCell

open class BaseTableViewCell : UITableViewCell
{
    weak var item: TableItem?
    public var tableItem: TableItem?
    {
        get { return item }
        set { item = newValue }
    }
    
    class var cellStyle: CellStyle { return .default }

    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder); commonInit()
    }

    public init(named reuseIdentifier: String? = identifier)
    {
        defer { commonInit() }
        super.init(style: type(of: self).cellStyle,
                   reuseIdentifier: reuseIdentifier)
    }

    open func commonInit() { /* subclasses can add subviews, etc */ }
    
    open override func prepareForReuse() { tableItem = nil }
    
    convenience override init(
        style ignored: UITableViewCell.CellStyle,
        reuseIdentifier: String?) { self.init(named: reuseIdentifier) }
}

// MARK: -

extension UITableViewCell:
    NibLoadable, TableItemCell
{
    // these methods allow subclasses
    // to "redirect" these values as
    // needed, i.e. to a button title
    
    // compiler complains about
    // naming this `text` so prefix
    // w/underscore like objC ivars
    @objc open var _text: String?
    {
        get { return textLabel?.text }
        set { textLabel?.text = newValue }
    }
    
    // see naming note for _text
    @objc open var _image: UIImage?
        {
        get { return imageView?.image }
        set { imageView?.image = newValue }
    }
    
    // see naming note for _text
    @objc open var _detailText: String?
    {
        get { return detailTextLabel?.text }
        set { detailTextLabel?.text = newValue }
    }
    
    // see naming note for _text
    @objc open var _textColor: UIColor?
        {
        get { return textLabel?.textColor }
        set { textLabel?.textColor = newValue }
    }
    
    // see naming note for _text
    @objc open var _detailTextColor: UIColor?
        {
        get { return detailTextLabel?.textColor }
        set { detailTextLabel?.textColor = newValue }
    }

    // see naming note for _text
    @objc open var _attributedText: NSAttributedString?
        {
        get { return textLabel?.attributedText }
        set { textLabel?.attributedText = newValue }
    }
    
    // see naming note for _text
    @objc open var _detailAttributedText: NSAttributedString?
        {
        get { return detailTextLabel?.attributedText }
        set { detailTextLabel?.attributedText = newValue }
    }
    
    // MARK:
    
    open var isSelectable: Bool { return selectionStyle != .none }
    open class var identifier: String { return String(describing: self) }
    @objc open class var height: CGFloat { return UITableView.automaticDimension }

    @objc open class func register(forUseIn tableView: UITableView)
    {
        if let _ = bundle.path(forResource: nibName, ofType: "nib")
        {
            let nib = UINib(nibName: nibName, bundle: bundle)
            tableView.register(nib, forCellReuseIdentifier: identifier)
        }
        else
        {
            tableView.register(self, forCellReuseIdentifier: identifier)
        }
    }

    @objc open var showActivityIndicator: Bool
    {
        set
        {   // subclass must override to restore non-nil accessoryView
            accessoryView = newValue ? // after setting newValue to false
                UIActivityIndicatorView(style: .gray) : nil
            (accessoryView as? UIActivityIndicatorView)?.startAnimating()
        }
        get { return (accessoryView as? UIActivityIndicatorView)?.isAnimating ?? false }
    }

    open func toggleCheckmark()
    {
        let unchecked = accessoryType == .none
        if unchecked || accessoryType == .checkmark
        {
            accessoryType = unchecked ? .checkmark : .none
        }
    }
}

// MARK: -

open class SubtitledTableViewCell : BaseTableViewCell
{
    override class var cellStyle: CellStyle { return .subtitle }
}

// MARK: -

open class LeftRightAlignedTableViewCell : BaseTableViewCell
{
    override class var cellStyle: CellStyle { return .value1 }
}

// MARK: -

open class RightLeftAlignedTableViewCell : BaseTableViewCell
{
    override class var cellStyle: CellStyle { return .value2 }
}
