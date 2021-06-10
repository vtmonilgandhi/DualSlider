import UIKit

extension RheemSlider: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc open func didDrag(_ panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
            
            case .began:
                
                if isHapticSnap { selectionFeedbackGenerator.prepare() }
                // determine thumb to drag
                let location = panGesture.location(in: slideView)
                draggedThumbIndex = closestThumb(point: location)
                if draggedThumbIndex >= 0 {
                    UIView.animate(withDuration: 0.3) {
                        self.lblGhostBuble.alpha = 1
                    }
                }
                
            case .ended, .cancelled, .failed:
                UIView.animate(withDuration: 0.3) {
                    self.lblGhostBuble.alpha = 0
                }
                if isHapticSnap { selectionFeedbackGenerator.end() }
                sendActions(for: .touchUpInside) // no bounds check for now (.touchUpInside vs .touchUpOutside)
                
                passSelectedValue()
                
                sendActions(for: [.valueChanged, .primaryActionTriggered])
                
            case .possible, .changed: break
            @unknown default:
                fatalError()
        }
        guard draggedThumbIndex >= 0 else { return }
        
        let slideViewLength = slideView.bounds.size(in: orientation)
        var targetPosition = panGesture.location(in: slideView).coordinate(in: orientation)
        let stepSizeInView = (snapStepSize / (maximumValue - minimumValue)) * slideViewLength
        
        // snap translation to stepSizeInView
        if snapStepSize > 0 {
            let translationSnapped = panGesture.translation(in: slideView).coordinate(in: orientation).rounded(stepSizeInView)
            if 0 == Int(translationSnapped) {
                return
            }
            panGesture.setTranslation(.zero, in: slideView)
        }
        
        // don't cross prev/next thumb and total range
        targetPosition = boundedDraggedThumbPosition(targetPosition: targetPosition, stepSizeInView: stepSizeInView)
        
        setLimitForThumb(atPosition: targetPosition)
        
    }
    
    // MARK: - Tap Gesture Handler
    @objc open func tapGesture(_ tapGesture: UITapGestureRecognizer) {
        
        if isHapticSnap { selectionFeedbackGenerator.prepare() }
        
        // determine thumb to drag
        let location = tapGesture.location(in: slideView)
        draggedThumbIndex = closestThumb(point: location)
        
        let slideViewLength = slideView.bounds.size(in: orientation)
        var targetPosition = tapGesture.location(in: slideView).coordinate(in: orientation)
        let stepSizeInView = (snapStepSize / (maximumValue - minimumValue)) * slideViewLength
        
        // don't cross prev/next thumb and total range
        targetPosition = boundedDraggedThumbPosition(targetPosition: targetPosition, stepSizeInView: stepSizeInView)
        setLimitForThumb(atPosition: targetPosition)
        
        passSelectedValue()
    }
    
    private func setLimitForThumb(atPosition position: CGFloat) {
        
        let slideViewLength = slideView.bounds.size(in: orientation)
        //Managing lower and upper thum position for deadband limit
        if sliderMode == .auto {
            var newValue = round((position / slideViewLength) * (maximumValue - minimumValue))
            if orientation == .vertical {
                newValue = maximumValue - newValue
            } else {
                newValue += minimumValue
            }
            // Check Min and Max value for Heat and Cool
            if draggedThumbIndex == 0 {
                if (maximumValue - deadBand) > heatMaxValue,
                   newValue > heatMaxValue {
                    return
                } else if (maximumValue - deadBand) <= heatMaxValue,
                          (deadBand + newValue) > (maximumValue) {
                    return
                }
            } else {
                if (minimumValue + deadBand) < coolMinValue,
                   newValue < coolMinValue {
                    return
                } else if (minimumValue + deadBand) >= coolMinValue,
                          (newValue - deadBand) < (minimumValue) {
                    return
                }
            }
        }
        
        updateDraggedThumbValue(relativeValue: position / slideViewLength)
        
        UIView.animate(withDuration: 0.1) {
            self.updateDraggedThumbPositionAndLabel()
            self.layoutIfNeeded()
        }
        
        sendActions(for: [.valueChanged, .primaryActionTriggered])
    }
    
    /// Adjusting thumb position to set their max and min limit.
    ///
    /// - Parameters:
    ///   - targetPosition: position at which thumb to be moved
    ///   - stepSizeInView: stepsize in pixels
    /// - Returns: targetposition's new value
    func boundedDraggedThumbPosition(targetPosition: CGFloat, stepSizeInView: CGFloat) -> CGFloat {
        
        var delta = snapStepSize > 0 ? stepSizeInView : thumbViews[draggedThumbIndex].frame.size(in: orientation) / 2
        
        if orientation == .horizontal && sliderMode == .auto {
            // Limitting the thumbview gap according to deadband value for horizontal orientation. Thumbview won't cross this limit and will get sticked to that position
            delta *= deadBand
        } else {
            delta = 0
        }
        
        if orientation == .horizontal { delta = -delta }
        
        let bottomLimit = draggedThumbIndex > 0
            ? thumbViews[draggedThumbIndex - 1].center.coordinate(in: orientation) - (delta)
            : slideView.bounds.bottom(in: orientation)
        let topLimit = draggedThumbIndex < thumbViews.count - 1
            ? thumbViews[draggedThumbIndex + 1].center.coordinate(in: orientation) + (delta)
            : slideView.bounds.top(in: orientation)
        
        if orientation == .vertical {
            return min(bottomLimit, max(targetPosition, topLimit))
        } else {
            return max(bottomLimit, min(targetPosition, topLimit))
        }
    }
    
    private func updateDraggedThumbValue(relativeValue: CGFloat) {
        var newValue = relativeValue * (maximumValue - minimumValue)
        if orientation == .vertical {
            newValue = maximumValue - newValue
        } else {
            newValue += minimumValue
        }
        
        newValue = newValue.rounded(snapStepSize)
        guard newValue != value[draggedThumbIndex] else { return }
        isSettingValue = true
        value[draggedThumbIndex] = newValue
        isSettingValue = false
        if (isHapticSnap && snapStepSize > 0) || relativeValue == 0 || relativeValue == 1 {
            selectionFeedbackGenerator.generateFeedback()
        }
    }
    
    private func updateDraggedThumbPositionAndLabel() {
        positionThumbView(draggedThumbIndex)
        if draggedThumbIndex < valueLabels.count {
            updateValueLabel(draggedThumbIndex)
        }
        updateThumbViewsAccordingToDeadBand()
    }
    
    func updateThumbViewsAccordingToDeadBand() {
        if sliderMode == .auto && value.count > 1 {
            if orientation == .vertical {
                // Moving thumb position according to new heating or cooling value.
                // If Difference between these two values is greater than or equal to deadband, then only thumbviews will get updated.
                // To resolve path crossing issues, we have to check if heat value (Index 0) and deadband value are greater than cooling value (index 1), then only we will have to move thumbviews.
                let valDiff = draggedThumbIndex == 0 ? abs(value[0] - value[1]) : value[1] - value[0]
                if (valDiff <= deadBand || value[0] + deadBand >= value[1]) {
                    switch draggedThumbIndex {
                        case 0:
                            value[1] = value[0] + deadBand
                            positionThumbView(1)
                        case 1:
                            value[0] = value[1] - deadBand
                            positionThumbView(0)
                        default :
                            break
                    }
                }
            } 
        }
    }
    
    private func closestThumb(point: CGPoint) -> Int {
        var closest = -1
        var minimumDistance = CGFloat.greatestFiniteMagnitude
        for i in 0 ..< thumbViews.count {
            let distance = point.distanceTo(thumbViews[i].center)
            if distance > minimumDistance { break }
            minimumDistance = distance
            closest = i
            // Drag enable only using thumb
            //if distance < thumbViews[i].diagonalSize {
            //closest = i
            //}
        }
        return closest
    }
    
    /// MARK: Pass Selected value to controller
    private func passSelectedValue() {
        switch sliderMode {
            case .heating:
                if let valueChangeHandler = sliderValueChangeHandler {
                    valueChangeHandler(roundedValue.first, nil, true)
                }
            case .cooling:
                if let valueChangeHandler = sliderValueChangeHandler {
                    valueChangeHandler(nil, roundedValue.first, false)
                }
                
            case .auto:
                if let valueChangeHandler = sliderValueChangeHandler {
                    let isHeatingThumb = draggedThumbIndex == 0 ? true : false
                    valueChangeHandler(roundedValue.first, roundedValue.last, isHeatingThumb)
                }
            case .fan:
                if let valueChangeHandler = fanSpeedChangeHandler {
                    let currentIndex = Int((value[0] / snapStepSize))
                    valueChangeHandler(currentIndex)
                }
            case .emergency:
                print("same as heat")
            case .off:
                print("off slider")
            case .geoFencing:
                if let valueChangeHandler = sliderValueChangeHandler {
                    valueChangeHandler(roundedValue.first, nil, true)
                }
        }
    }
}
