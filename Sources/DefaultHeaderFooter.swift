//
//  DefaultHeaderFooter.swift
//  Created by J.Rodden
//  Copyright © 2018 DD/MF & Associates. All rights reserved.
//

import UIKit

/********************************************************
 To use a custom headerFooterView, you should override
 these properties and either retun nil, or return the
 analogous items w/in your custom view. They are
 automatically set to the model's title and detail w/in
 the section's configure(headerView:forSection:) and
 configure(footerView:forSection:) methods.
 
 public extension UITableViewHeaderFooterView
 {
 override var textLabel: UILabel? { return nil }
 override var detailTextLabel: UILabel? { return nil }
 }*/

open class DefaultHeaderFooter : UITableViewHeaderFooterView
{
    public weak var section: TableSection?
    open override func prepareForReuse() { section = nil }
    
    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder); commonInit()
    }
    
    convenience init(named reuseIdentifier: String? = identifier)
    {
        self.init(reuseIdentifier: reuseIdentifier)
    }
    
    open func commonInit() { /* subclasses can add subviews, etc */ }

    override public init(reuseIdentifier: String? = identifier)
    {
        defer { commonInit() }
        super.init(reuseIdentifier: reuseIdentifier)
    }
}

// MARK: -

extension UITableViewHeaderFooterView: NibLoadable
{
    open class var identifier: String { return String(describing: self) }
    @objc open class var height: CGFloat { return UITableView.automaticDimension }

    @objc open class func register(forUseIn tableView: UITableView)
    {
        if let _ = bundle.path(forResource: nibName, ofType: "nib")
        {
            let nib = UINib(nibName: nibName, bundle: bundle)
            tableView.register(nib, forHeaderFooterViewReuseIdentifier: identifier)
        }
        else
        {
            tableView.register(self, forHeaderFooterViewReuseIdentifier: identifier)
        }
    }
}

