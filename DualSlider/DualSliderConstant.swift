import Foundation
import UIKit

enum SliderMode: String {
    case heating = "Heating"
    case cooling = "Cooling"
    case fan = "Fan Only"
    case auto = "Auto"
    case emergency = "Emergency Heat"
    case off = "Off"
    case geoFencing = "Geo Fencing"
    
    var color: UIColor {
        switch self {
            case .heating:
                return SliderStateColor.heatingStateColor
            case .cooling:
                return SliderStateColor.coolingStateColor
            case .fan:
                return SliderStateColor.fanStateColor
            case .auto :
                return SliderStateColor.unknownStateColor
            case .emergency:
                return SliderStateColor.heatingStateColor
            case .off:
                return SliderStateColor.offStateColor
            case .geoFencing:
                return SliderStateColor.geoFencingColor
                
        }
    }
}

struct SliderStateColor {
    static let heatingStateColor = UIColor.orange
    static let coolingStateColor = UIColor.red
    static let disabledStateColor = UIColor.gray
    static let fanStateColor = UIColor.gray
    static let fanStepColor = UIColor.white
    static let unknownStateColor = UIColor.white
    static let offStateColor = UIColor.clear
    static let geoFencingColor = UIColor.white
}

struct ThumbImageName {
    static let verticalImageName = "bubble_vertical"
    static let horizontalImageName = "bubble_horizontal"
}
