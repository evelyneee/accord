//
//  Github.swift
//  Accord
//
//  Created by evelyn on 2022-01-03.
//

import Foundation
import SwiftUI

// Original SVG from SimpleIcons
// All rights reserved to Github
struct GithubIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.size.width
        let height = rect.size.height
        path.move(to: CGPoint(x: 0.5 * width, y: 0.01237 * height))
        path.addCurve(to: CGPoint(x: 0, y: 0.51238 * height), control1: CGPoint(x: 0.22375 * width, y: 0.01237 * height), control2: CGPoint(x: 0, y: 0.23625 * height))
        path.addCurve(to: CGPoint(x: 0.34187 * width, y: 0.98675 * height), control1: CGPoint(x: 0, y: 0.73333 * height), control2: CGPoint(x: 0.14325 * width, y: 0.92071 * height))
        path.addCurve(to: CGPoint(x: 0.37604 * width, y: 0.96271 * height), control1: CGPoint(x: 0.36688 * width, y: 0.99146 * height), control2: CGPoint(x: 0.37604 * width, y: 0.976 * height))
        path.addCurve(to: CGPoint(x: 0.37542 * width, y: 0.87771 * height), control1: CGPoint(x: 0.37604 * width, y: 0.95083 * height), control2: CGPoint(x: 0.37563 * width, y: 0.91938 * height))
        path.addCurve(to: CGPoint(x: 0.207 * width, y: 0.81063 * height), control1: CGPoint(x: 0.23633 * width, y: 0.90788 * height), control2: CGPoint(x: 0.207 * width, y: 0.81063 * height))
        path.addCurve(to: CGPoint(x: 0.15138 * width, y: 0.7375 * height), control1: CGPoint(x: 0.18425 * width, y: 0.75292 * height), control2: CGPoint(x: 0.15138 * width, y: 0.7375 * height))
        path.addCurve(to: CGPoint(x: 0.15488 * width, y: 0.70713 * height), control1: CGPoint(x: 0.10608 * width, y: 0.7065 * height), control2: CGPoint(x: 0.15488 * width, y: 0.70713 * height))
        path.addCurve(to: CGPoint(x: 0.23146 * width, y: 0.75862 * height), control1: CGPoint(x: 0.20508 * width, y: 0.71062 * height), control2: CGPoint(x: 0.23146 * width, y: 0.75862 * height))
        path.addCurve(to: CGPoint(x: 0.37708 * width, y: 0.80021 * height), control1: CGPoint(x: 0.27604 * width, y: 0.83508 * height), control2: CGPoint(x: 0.3485 * width, y: 0.813 * height))
        path.addCurve(to: CGPoint(x: 0.40875 * width, y: 0.73333 * height), control1: CGPoint(x: 0.38158 * width, y: 0.76788 * height), control2: CGPoint(x: 0.39446 * width, y: 0.74583 * height))
        path.addCurve(to: CGPoint(x: 0.181 * width, y: 0.48625 * height), control1: CGPoint(x: 0.29771 * width, y: 0.72083 * height), control2: CGPoint(x: 0.181 * width, y: 0.67783 * height))
        path.addCurve(to: CGPoint(x: 0.23246 * width, y: 0.35208 * height), control1: CGPoint(x: 0.181 * width, y: 0.43167 * height), control2: CGPoint(x: 0.20037 * width, y: 0.38708 * height))
        path.addCurve(to: CGPoint(x: 0.23683 * width, y: 0.21975 * height), control1: CGPoint(x: 0.22683 * width, y: 0.33946 * height), control2: CGPoint(x: 0.20996 * width, y: 0.28863 * height))
        path.addCurve(to: CGPoint(x: 0.37433 * width, y: 0.271 * height), control1: CGPoint(x: 0.23683 * width, y: 0.21975 * height), control2: CGPoint(x: 0.27871 * width, y: 0.20633 * height))
        path.addCurve(to: CGPoint(x: 0.49933 * width, y: 0.25413 * height), control1: CGPoint(x: 0.41433 * width, y: 0.25988 * height), control2: CGPoint(x: 0.45683 * width, y: 0.25438 * height))
        path.addCurve(to: CGPoint(x: 0.62433 * width, y: 0.271 * height), control1: CGPoint(x: 0.54183 * width, y: 0.25438 * height), control2: CGPoint(x: 0.58433 * width, y: 0.25988 * height))
        path.addCurve(to: CGPoint(x: 0.76121 * width, y: 0.21975 * height), control1: CGPoint(x: 0.71933 * width, y: 0.20633 * height), control2: CGPoint(x: 0.76121 * width, y: 0.21975 * height))
        path.addCurve(to: CGPoint(x: 0.76621 * width, y: 0.35208 * height), control1: CGPoint(x: 0.78808 * width, y: 0.28863 * height), control2: CGPoint(x: 0.77121 * width, y: 0.33946 * height))
        path.addCurve(to: CGPoint(x: 0.81746 * width, y: 0.48625 * height), control1: CGPoint(x: 0.79808 * width, y: 0.38708 * height), control2: CGPoint(x: 0.81746 * width, y: 0.43167 * height))
        path.addCurve(to: CGPoint(x: 0.58933 * width, y: 0.73292 * height), control1: CGPoint(x: 0.81746 * width, y: 0.67833 * height), control2: CGPoint(x: 0.70058 * width, y: 0.72063 * height))
        path.addCurve(to: CGPoint(x: 0.62308 * width, y: 0.82542 * height), control1: CGPoint(x: 0.60683 * width, y: 0.74792 * height), control2: CGPoint(x: 0.62308 * width, y: 0.77858 * height))
        path.addCurve(to: CGPoint(x: 0.62246 * width, y: 0.96233 * height), control1: CGPoint(x: 0.62308 * width, y: 0.89233 * height), control2: CGPoint(x: 0.62246 * width, y: 0.94608 * height))
        path.addCurve(to: CGPoint(x: 0.65683 * width, y: 0.98608 * height), control1: CGPoint(x: 0.62246 * width, y: 0.97546 * height), control2: CGPoint(x: 0.63121 * width, y: 0.99108 * height))
        path.addCurve(to: CGPoint(x: width, y: 0.51238 * height), control1: CGPoint(x: 0.85688 * width, y: 0.9205 * height), control2: CGPoint(x: width, y: 0.733 * height))
        path.addCurve(to: CGPoint(x: 0.5 * width, y: 0.01238 * height), control1: CGPoint(x: width, y: 0.23625 * height), control2: CGPoint(x: 0.77612 * width, y: 0.01238 * height))
        return path
    }
}
