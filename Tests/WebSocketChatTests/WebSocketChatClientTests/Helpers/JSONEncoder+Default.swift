//
//  JSONEncoder+Default.swift
//  
//
//  Created by Egor on 11.12.2021.
//

import Foundation

extension JSONEncoder {
    static var `default`: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .formatted(.serverFormatter)
        
        return encoder
    }
}
