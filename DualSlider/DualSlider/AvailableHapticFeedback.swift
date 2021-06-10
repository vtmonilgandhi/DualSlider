import Foundation
import UIKit

/// Wrapper for UIFeedbackGenerator that compiles on iOS 9
public class AvailableHapticFeedback {
    public enum Style: CaseIterable {
        case selection
        case impactLight, impactMedium, impactHeavy
        case notificationSuccess, notificationWarning, notificationError
    }
    
    public let style: Style
    
    public init(style: Style = .selection) {
        self.style = style
    }
    
    public func prepare() {
        if #available(iOS 10.0, *) {
            feedbackGenerator.prepare()
        }
    }
    
    public func generateFeedback() {
        if #available(iOS 10.0, *) {
            feedbackGenerator.generate(style: style)
        }
    }
    
    public func end() {
        _anyFeedbackGenerator = nil
    }
    
    @available(iOS 10.0, *)
    public var feedbackGenerator: UIFeedbackGenerator & AvailableHapticFeedbackGenerator {
        if nil == _anyFeedbackGenerator {
            createFeedbackGenerator()
        }
        // swiftlint:disable force_cast force_unwrapping
        return _anyFeedbackGenerator! as! UIFeedbackGenerator & AvailableHapticFeedbackGenerator
        // swiftlint:enable force_cast force_unwrapping
    }
    
    public var _anyFeedbackGenerator: Any?
    
    @available(iOS 10.0, *)
    public func createFeedbackGenerator() {
        switch style {
            case .selection:
                _anyFeedbackGenerator = UISelectionFeedbackGenerator()
            case .impactLight:
                _anyFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            case .impactMedium:
                _anyFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
            case .impactHeavy:
                _anyFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
            case .notificationSuccess, .notificationWarning, .notificationError:
                _anyFeedbackGenerator = UINotificationFeedbackGenerator()
        }
    }
}

protocol AvailableHapticFeedbackGenerator {
    public func generate(style: AvailableHapticFeedback.Style)
}

@available(iOS 10.0, *)
extension UISelectionFeedbackGenerator: AvailableHapticFeedbackGenerator {
    public func generate(style: AvailableHapticFeedback.Style) {
        selectionChanged()
    }
}

@available(iOS 10.0, *)
extension UIImpactFeedbackGenerator: AvailableHapticFeedbackGenerator {
    public func generate(style: AvailableHapticFeedback.Style) {
        impactOccurred()
    }
}

@available(iOS 10.0, *)
extension UINotificationFeedbackGenerator: AvailableHapticFeedbackGenerator {
    public func generate(style: AvailableHapticFeedback.Style) {
        let notificationFeedbackType: UINotificationFeedbackGenerator.FeedbackType
        switch style {
            case .notificationWarning:
                notificationFeedbackType = .warning
            case .notificationError:
                notificationFeedbackType = .error
            default:
                notificationFeedbackType = .success
        }
        notificationOccurred(notificationFeedbackType)
    }
}
