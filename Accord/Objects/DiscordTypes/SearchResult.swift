//
//  SearchResult.swift
//  Accord
//
//  Created by Serena on 18/06/2022
//
	

import Foundation

struct SearchResult: Codable {
    let total_results: Int
    let messages: [[Message]]
}
