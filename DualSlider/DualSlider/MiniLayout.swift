import UIKit

public extension UIView {
    /// Set constant attribute. Example: constrain(.Width, to: 17)
    @discardableResult func constrain(_ at: NSLayoutConstraint.Attribute, to: CGFloat = 0, ratio: CGFloat = 1, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: self, attribute: at, relatedBy: relation, toItem: nil, attribute: .notAnAttribute, multiplier: ratio, constant: to)
        addConstraintWithoutConflict(constraint)
        return constraint
    }
    
    /// Pin subview at a specific place. Example: constrain(label, at: .Top)
    @discardableResult func constrain(_ subview: UIView, at: NSLayoutConstraint.Attribute, diff: CGFloat = 0, ratio: CGFloat = 1, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(item: subview, attribute: at, relatedBy: relation, toItem: self, attribute: at, multiplier: ratio, constant: diff)
        addConstraintWithoutConflict(constraint)
        return constraint
    }
    
    /// Pin two subviews to each other. Example:
    ///
    /// constrain(label, at: .Leading, to: textField)
    ///
    /// constrain(textField, at: .Top, to: label, at: .Bottom, diff: 8)
    @discardableResult func constrain(_ subview: UIView, at: NSLayoutConstraint.Attribute, to subview2: UIView, at at2: NSLayoutConstraint.Attribute = .notAnAttribute, diff: CGFloat = 0, ratio: CGFloat = 1, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        let at2real = at2 == .notAnAttribute ? at : at2
        let constraint = NSLayoutConstraint(item: subview, attribute: at, relatedBy: relation, toItem: subview2, attribute: at2real, multiplier: ratio, constant: diff)
        addConstraintWithoutConflict(constraint)
        return constraint
    }
    
    /// Add subview pinned to specific places. Example: addConstrainedSubview(button, constrain: .CenterX, .CenterY)
    @discardableResult func addConstrainedSubview(_ subview: UIView, constrain: NSLayoutConstraint.Attribute...) -> [NSLayoutConstraint] {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        return constrain.map { self.constrain(subview, at: $0) }
    }
    
    func addConstraintWithoutConflict(_ constraint: NSLayoutConstraint) {
        removeConstraints(constraints.filter {
            constraint.firstItem === $0.firstItem
                && constraint.secondItem === $0.secondItem
                && constraint.firstAttribute == $0.firstAttribute
                && constraint.secondAttribute == $0.secondAttribute
        })
        addConstraint(constraint)
    }
}
