//
//  UIView+.swift
//
//  Created by J.Rodden on 11/1/18.
//  Copyright © 2018 DD/MF & Associates. All rights reserved.
//

import UIKit

// recurisvely search for first UITextField w/in
func find<T>(_: T.Type, in view: UIView) -> T?
{
    for view in view.subviews
    {
        if let it = view as? T ??
            find(T.self, in: view) { return it }
    }
    
    return nil
}

extension UIView.AutoresizingMask
{
    public static var flexibleHeightAndWidth: UIView.AutoresizingMask
    {
        return UIView.AutoresizingMask(rawValue:
            UIView.AutoresizingMask.flexibleWidth.rawValue +
                UIView.AutoresizingMask.flexibleHeight.rawValue)
    }
}
