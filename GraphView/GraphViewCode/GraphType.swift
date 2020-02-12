//
//  GraphType.swift
//  GraphView
//
//  Created by Kelly Roach on 8/18/18.
//

// The type of the current graph we are showing.
enum GraphType {
    case simple
    case multiOne
    case multiTwo
    case dark
    case bar
    case dot
    case pink
    case blueOrange
    
    mutating func next() {
        switch(self) {
        case .simple:
            self = .multiOne
        case .multiOne:
            self = .multiTwo
        case .multiTwo:
            self = .dark
        case .dark:
            self = .bar
        case .bar:
            self = .dot
        case .dot:
            self = .pink
        case .pink:
            self = .blueOrange
        case .blueOrange:
            self = .simple
        }
    }

    var title: String {
        switch(self) {
        case .simple:
            return "SIMPLE"
        case .multiOne:
            return "MULTI 1"
        case .multiTwo:
            return "MULTI 2"
        case .dark:
            return "DARK"
        case .bar:
            return "BAR"
        case .dot:
            return "DOT"
        case .pink:
            return "PINK"
        case .blueOrange:
            return "BLUE ORANGE"
        }
    }
}
