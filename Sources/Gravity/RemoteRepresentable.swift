//
//  File.swift
//  
//
//  Created by Arthur Guiot on 09/04/2023.
//

import Foundation

public protocol RemoteRepresentable: Codable, Hashable, Identifiable where ID: Codable & Hashable {}
