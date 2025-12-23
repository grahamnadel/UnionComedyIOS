//
//  TeamImageEnum.swift
//  Union
//
//  Created by Graham Nadel on 12/23/25.
//

import Foundation
import SwiftUI

enum TeamImageEnum {
    case Babe
    case CandyCigarette
    case Clyde
    case Medusa
    case Neighbors
    case StudentDriver
    
    var teamName: String {
        switch self {
        case .Babe:
            return "Babe"
        case .CandyCigarette:
            return "Candy Cigarette"
        case .Clyde:
            return "Clyde"
        case .Medusa:
            return "Medusa"
            case .Neighbors:
            return "Neighbors"
        case .StudentDriver:
            return "Student Driver"
        }
    }
    
    var imageName: String {
        switch self {
        case .Babe:
            return "Babe"
        case .CandyCigarette:
            return "Candy cig"
        case .Clyde:
            return "Clyde"
        case .Medusa:
            return "Medusa"
            case .Neighbors:
            return "Neighbors"
        case .StudentDriver:
            return "Student driver"
        }
    }
    
    func image(teamName: String) -> Image {
        Image(imageName)
    }
}
