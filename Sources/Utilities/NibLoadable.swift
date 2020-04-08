//
//  NibLoadable.swift
//  Created by J.Rodden
//  Copyright © 2018 DD/MF & Associates. All rights reserved.
//

import Foundation

public protocol NibLoadable: class
{
}

extension NibLoadable
{
    public static var bundle: Bundle { return Bundle(for: self) }
    public static var nibName: String { return String(describing: self) }

    public static func fromNib() -> Self
    {
        guard let this = bundle.loadNibNamed(
            nibName, owner: nil, options: nil)?.first else
        {
            fatalError("Could not load \(nibName) in \(bundle)")
        }
        
        return this as! Self
    }
}

