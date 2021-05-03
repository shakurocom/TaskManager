//
//  Copyright © 2019 Shakuro. All rights reserved.
//

import UIKit

public extension UIColor {

    /// Creates UIColor instance from random components in range
    ///
    /// - Parameters:
    ///   - redRange: The range for red color component max range is 0..255
    ///   - greenRange: The range for green color component max range is 0..255
    ///   - blueRange: The range for blue color component max range is 0..255
    ///   - alpha: The alpha value of color
    /// - Returns: A random color
    static func random(redRange: ClosedRange<Int> = 0...255,
                       greenRange: ClosedRange<Int> = 0...255,
                       blueRange: ClosedRange<Int> = 0...255,
                       alpha: CGFloat = 1.0) -> UIColor {
        let redValue =  CGFloat(Int.random(in: redRange)) / 255.0
        let greenValue  =  CGFloat(Int.random(in: greenRange)) / 255.0
        let blueValue  =  CGFloat(Int.random(in: blueRange)) / 255.0
        return UIColor(red: redValue,
                       green: greenValue,
                       blue: blueValue,
                       alpha: alpha)
    }

    /// Inites UIColor with decimal representation
    ///
    /// - Parameter decimalColor: A decimal representation color
    convenience init(decimalColor: UInt32) {
        let mask = 0x000000FF
        let rComponent: Int = Int(decimalColor >> 16) & mask
        let gComponent: Int = Int(decimalColor >> 8) & mask
        let bComponent: Int = Int(decimalColor) & mask

        let red: CGFloat = CGFloat(rComponent) / 255.0
        let green: CGFloat = CGFloat(gComponent) / 255.0
        let blue: CGFloat  = CGFloat(bComponent) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    /// Inites UIColor with hexadecimal representation
    ///
    /// - Parameter hex: A hexadecimal color string
    convenience init(hex: String) {
        let validateHex: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner: Scanner = Scanner(string: validateHex)

        if validateHex.hasPrefix("#") {
            scanner.scanLocation = 1
        }
        var color: UInt32 = 0
        scanner.scanHexInt32(&color)
        self.init(decimalColor: color)
    }

    /// Generates image from color
    ///
    /// - Parameters:
    ///   - destinationSize: The size of result image
    ///   - scale: UIImage.scale, Pass 0 for auto selection
    ///   - opaque: If true result image will be opaque
    /// - Returns: UIImage instance or nil
    func generateImage(destinationSize: CGSize = CGSize(width: 1.0, height: 1.0),
                       scale: CGFloat = 0,
                       opaque: Bool = false) -> UIImage? {
        guard !destinationSize.equalTo(CGSize.zero) else {
            return nil
        }
        defer {
            UIGraphicsEndImageContext()
        }
        let drawRect = CGRect(origin: CGPoint(x: 0, y: 0), size: destinationSize)
        UIGraphicsBeginImageContextWithOptions(drawRect.size, opaque, scale)
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
        currentContext.setFillColor(cgColor)
        currentContext.fill(drawRect)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

}
