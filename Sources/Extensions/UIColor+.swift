//
//  UIColor+.swift
//
//  Created by J.Rodden on 11/1/18.
//  Copyright © 2018 DD/MF & Associates. All rights reserved.
//

import UIKit

extension UIColor
{
    convenience init(rgb hexColor: Int)
    {
        let bitFilter = 0xFF
        
        let red = ((hexColor >> 16) & bitFilter)
        let grn = ((hexColor >> 08) & bitFilter)
        let blu = ((hexColor >> 00) & bitFilter)
        
        self.init(red:   CGFloat(red) / 255.0,
                  green: CGFloat(grn) / 255.0,
                  blue:  CGFloat(blu) / 255.0, alpha: 1.0)
    }
}
