//
//  BarButtonItem+.swift
//  GenericTableView
//
//  Created by J.Rodden on 11/29/18.
//  Copyright © 2018 DD/MF & Associates. All rights reserved.
//

import UIKit

fileprivate extension UIBarButtonItem
{
    static private var blockKey = 0
    
    @objc func executeBlock() { wrappedBlock?(self) }

    var wrappedBlock: Block?
    {
        get
        {
            return objc_getAssociatedObject(self, &type(of: self).blockKey) as? Block
        }
        set
        {
            target = self; action = #selector(executeBlock)
            objc_setAssociatedObject(self, &type(of: self).blockKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

// MARK: -

public extension UIBarButtonItem
{
    var block: Block?
    {
        get { return wrappedBlock }
        set { wrappedBlock = newValue }
    }
    
    static var defaultBlock: Block
    { return { (_: UIBarButtonItem) in return } }
    
    typealias Block = ((UIBarButtonItem)->Void)

    convenience init(title: String?,
                     style: UIBarButtonItem.Style,
                     block: @escaping Block = defaultBlock )
    {
        self.init(title: title, style: style, target: nil, action: nil)
        self.block = block
    }
    
    convenience init(image: UIImage?,
                     style: UIBarButtonItem.Style,
                     block: @escaping Block = defaultBlock )
    {
        self.init(image: image, style: style, target: nil, action: nil)
        self.block = block
    }

    convenience init(barButtonSystemItem item: UIBarButtonItem.SystemItem,
                     block: @escaping Block = defaultBlock )
    {
        self.init(barButtonSystemItem: item, target: nil, action: nil)
        self.block = block
    }
    
    convenience init(image: UIImage?,
                     landscapeImagePhone: UIImage?,
                     style: UIBarButtonItem.Style,
                     block: @escaping Block = defaultBlock )
    {
        self.init(image: image,
                  landscapeImagePhone: landscapeImagePhone,
                  style: style, target: nil, action: nil)
        self.block = block
    }
}
