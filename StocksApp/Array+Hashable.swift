//
//  Array+Hashable.swift
//
//  Created by Anton Makeev on 19.12.2020.
//

import Foundation

extension Array where Element: Hashable {
    func unique() -> Array {
        Array(Set(self))
    }
}
