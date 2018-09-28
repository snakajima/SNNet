//
//  String+localized.swift
//
//  Created by satoshi on 10/15/15.
//  Copyright © 2015 Satoshi Nakajima. All rights reserved.
//

import Foundation

extension String {
    var localized:String {
        return NSLocalizedString(self, comment:"")
    }
}
