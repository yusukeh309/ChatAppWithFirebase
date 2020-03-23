//
//  UIColor-Extension.swift
//  ChatAppWithFirebase
//
//  Created by Uske on 2020/03/18.
//  Copyright © 2020 Uske. All rights reserved.
//

import UIKit

extension UIColor {
    
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return self.init(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
    
}
