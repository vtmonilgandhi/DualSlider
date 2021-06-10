import UIKit

extension CGFloat {
    public func truncated(_ step: CGFloat) -> CGFloat {
        return step.isNormal ? self - remainder(dividingBy: step) : self
    }
    
    public func rounded(_ step: CGFloat) -> CGFloat {
        guard step.isNormal && isNormal else { return self }
        return (self / step).rounded() * step
    }
}

extension CGPoint {
    public func distanceTo(_ point: CGPoint) -> CGFloat {
        let (dx, dy) = (x - point.x, y - point.y)
        return hypot(dx, dy)
    }
    
    public func coordinate(in axis: NSLayoutConstraint.Axis) -> CGFloat {
        switch axis {
            case .vertical:
                return y
            case .horizontal:
                return x
            @unknown default:
                fatalError()
        }
    }
}

extension CGRect {
    public func size(in axis: NSLayoutConstraint.Axis) -> CGFloat {
        switch axis {
            case .vertical:
                return height
            case .horizontal:
                return width
            @unknown default:
                fatalError()
        }
    }
    
    public func bottom(in axis: NSLayoutConstraint.Axis) -> CGFloat {
        switch axis {
            case .vertical:
                return maxY
            case .horizontal:
                return minX
            @unknown default:
                fatalError()
        }
    }
    
    public func top(in axis: NSLayoutConstraint.Axis) -> CGFloat {
        switch axis {
            case .vertical:
                return minY
            case .horizontal:
                return maxX
            @unknown default:
                fatalError()
        }
    }
}

extension UIView {
    public var diagonalSize: CGFloat { return hypot(frame.width, frame.height) }
    
    public var actualTintColor: UIColor {
        var tintedView: UIView? = self
        while let currentView = tintedView, nil == currentView.tintColor {
            tintedView = currentView.superview
        }
        return tintedView?.tintColor ?? .blue
    }
    
    public func removeFirstConstraint(where: (_: NSLayoutConstraint) -> Bool) {
        if let constrainIndex = constraints.firstIndex(where: `where`) {
            removeConstraint(constraints[constrainIndex])
        }
    }
    
    public func addShadow() {
        layer.shadowColor = UIColor.gray.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 0.5
    }
}

extension Array where Element: UIView {
    public mutating func removeViewsStartingAt(_ index: Int) {
        guard index >= 0 && index < count else { return }
        self[index ..< count].forEach { $0.removeFromSuperview() }
        removeLast(count - index)
    }
}

extension UIImageView {
    public func blur(_ on: Bool) {
        if on {
            guard nil == viewWithTag(UIImageView.blurViewTag) else { return }
            let blurImage = image?.withRenderingMode(.alwaysTemplate)
            let blurView = UIImageView(image: blurImage)
            blurView.tag = UIImageView.blurViewTag
            blurView.tintColor = .white
            blurView.alpha = 0.5
            addConstrainedSubview(blurView, constrain: .top, .bottom, .left, .right)
            layer.shadowOpacity /= 2
        } else {
            guard let blurView = viewWithTag(UIImageView.blurViewTag) else { return }
            blurView.removeFromSuperview()
            layer.shadowOpacity *= 2
        }
    }
    
    public static var blurViewTag: Int { return 898_989 } // swiftlint:disable:this numbers_smell
}

extension NSLayoutConstraint.Attribute {
    public var opposite: NSLayoutConstraint.Attribute {
        switch self {
            case .left: return .right
            case .right: return .left
            case .top: return .bottom
            case .bottom: return .top
            case .leading: return .trailing
            case .trailing: return .leading
            case .leftMargin: return .rightMargin
            case .rightMargin: return .leftMargin
            case .topMargin: return .bottomMargin
            case .bottomMargin: return .topMargin
            case .leadingMargin: return .trailingMargin
            case .trailingMargin: return .leadingMargin
            default: return self
        }
    }
    
    public var inwardSign: CGFloat {
        switch self {
            case .top, .topMargin: return 1
            case .bottom, .bottomMargin: return -1
            case .left, .leading, .leftMargin, .leadingMargin: return 1
            case .right, .trailing, .rightMargin, .trailingMargin: return -1
            default: return 1
        }
    }
    
    public var perpendicularCenter: NSLayoutConstraint.Attribute {
        switch self {
            case .left, .leading, .leftMargin, .leadingMargin, .right, .trailing, .rightMargin, .trailingMargin, .centerX:
                return .centerY
            default:
                return .centerX
        }
    }
    
    public static func center(in axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint.Attribute {
        switch axis {
            case .vertical:
                return .centerY
            case .horizontal:
                return .centerX
            @unknown default:
                fatalError()
        }
    }
    
    public static func top(in axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint.Attribute {
        switch axis {
            case .vertical:
                return .top
            case .horizontal:
                return .trailing
            @unknown default:
                fatalError()
        }
    }
    
    public static func bottom(in axis: NSLayoutConstraint.Axis) -> NSLayoutConstraint.Attribute {
        switch axis {
            case .vertical:
                return .bottom
            case .horizontal:
                return .leading
            @unknown default:
                fatalError()
        }
    }
}

extension CACornerMask {
    public static func direction(_ attribute: NSLayoutConstraint.Attribute) -> CACornerMask {
        switch attribute {
            case .bottom:
                return [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            case .top:
                return [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            case .leading, .left:
                return [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            case .trailing, .right:
                return [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            default:
                return []
        }
    }
}

extension UIImage {
    public static func circle(diameter: CGFloat = 44, width: CGFloat = 0.5, color: UIColor? = UIColor.lightGray.withAlphaComponent(0.5), fill: UIColor? = .white) -> UIImage? {
        let circleLayer = CAShapeLayer()
        circleLayer.fillColor = fill?.cgColor
        circleLayer.strokeColor = color?.cgColor
        circleLayer.lineWidth = width
        let margin = width * 2
        let circle = UIBezierPath(ovalIn: CGRect(x: margin, y: margin, width: diameter, height: diameter))
        circleLayer.bounds = CGRect(x: 0, y: 0, width: diameter + margin * 2, height: diameter + margin * 2)
        circleLayer.path = circle.cgPath
        UIGraphicsBeginImageContextWithOptions(circleLayer.bounds.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        circleLayer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension String {
    
    public func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
    
    public func heightOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.height
    }
    
    public func sizeOfString(usingFont font: UIFont) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: fontAttributes)
    }
}
