//
//  JSONDecoder+Default.swift
//  
//
//  Created by Egor on 11.12.2021.
//

import Foundation

extension JSONDecoder {
    static var `default`: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(.serverFormatter)
        
        return decoder
    }
}
