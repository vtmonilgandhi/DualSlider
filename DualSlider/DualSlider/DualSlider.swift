import UIKit

open class DualSlider: UIControl {
    
        // MARK: - Variables
    public var thumbViews: [UIImageView] = []
    public var valueLabels: [UITextField] = [] // UILabels are a pain to layout, text fields look nice as-is.
    public var trackView = UIView()
    public var lblGhostBuble = UILabel()
    public var isGeoFencing = false
    public let slideView = UIView()
    public let panGestureView = UIView()
    
    public var shapeLayer = CAShapeLayer()
    public var fanStepLayer = CAShapeLayer()
    
        //Upper and lower layer for auto slider (red and blue color layer)
    public var lowerLayer = CAShapeLayer()
    public var upperLayer = CAShapeLayer()
    
        /// Settings Variables
    public var dotRadius: Float = 6
    public let margin: CGFloat = 32
    public var isSettingValue = false
    public var draggedThumbIndex: Int = -1
    public var sliderMode: SliderMode = .cooling
    public var arrFanMode: [String] = []
    public var fanStepColor: CGColor = SliderStateColor.fanStepColor.cgColor
    public var geoFencingUnit = "Miles"
    public var unlockInterval: Double = 0
    public weak var unlockTimer: Timer?
    lazy var defaultThumbImage: UIImage? = .circle()
        /// generate haptic feedback when hitting snap steps
    public var isHapticSnap: Bool = true
    public var selectionFeedbackGenerator = AvailableHapticFeedback()
    
        // MARK: - Computed properties
    public var thumbCount: Int {
        get {
            return thumbViews.count
        }
        set {
            guard newValue > 0 else { return }
            adjustThumbCountToValueCount()
        }
    }
    
    public var thumbImage: UIImage? {
        didSet {
            thumbViews.forEach { $0.image = defaultThumbImage }
            setupTrackLayoutMargins()
            invalidateIntrinsicContentSize()
        }
    }
    
    public var trackWidth: CGFloat = 6 {
        didSet {
            let widthAttribute: NSLayoutConstraint.Attribute = orientation == .vertical ? .width : .height
            trackView.removeFirstConstraint { $0.firstAttribute == widthAttribute }
            trackView.constrain(widthAttribute, to: trackWidth)
        }
    }
    
        //Slider current values
    public var value: [CGFloat] = [] {
        didSet {
            if isSettingValue { return }
            adjustThumbCountToValueCount()
            adjustValuesToStepAndLimits()
            for i in 0 ..< valueLabels.count {
                updateValueLabel(i)
            }
        }
    }
    
    public var minimumValue: CGFloat = 0 { didSet { adjustValuesToStepAndLimits() } }
    public var maximumValue: CGFloat = 1 { didSet { adjustValuesToStepAndLimits() } }
    public var coolMinValue: CGFloat = 0
    public var heatMaxValue: CGFloat = 1
        /// snap thumbs to specific values, evenly spaced. (default = 0: allow any value)
    public var snapStepSize: CGFloat = 0 { didSet { adjustValuesToStepAndLimits() } }
    
    public var roundedValue: [Int] {
        return value.map({Int($0)})
    }
    
    public var deadBand: CGFloat = 5 {
        willSet {
            if sliderMode == .auto {
                let diffVal = value[1] - value[0]
                if diffVal < newValue {
                    if value[1] - newValue >= minimumValue {
                        value[0] = value[1] - newValue
                    } else if value[0] - newValue <= minimumValue {
                        value[0] = minimumValue
                        value[1] = value[0] + newValue
                    } else {
                        value[0] = value[1] - newValue
                    }
                }
            }
        }
    }
    
    public var currentFanSpeed: Int = 0 {
        willSet {
            if sliderMode == .fan {
                snapStepSize = (maximumValue / CGFloat(arrFanMode.count - 1))
                let currentVal = ((maximumValue / CGFloat(arrFanMode.count-1)) * CGFloat(newValue))
                value = [currentVal]
            }
        }
    }
    
    public var currentHeatValue: Int = 0 {
        willSet {
                //updateHeating(newValue: newValue)
            changeCurrentValue(newValue: CGFloat(newValue), type: .heating)
        }
    }
    
    public var currentCoolValue: Int = 0 {
        willSet {
                //updateCooling(newValue: newValue)
            changeCurrentValue(newValue: CGFloat(newValue), type: .cooling)
        }
    }
    
        /// show value labels next to thumbs. (default: show no label)
    public var valueLabelPosition: NSLayoutConstraint.Attribute = .notAnAttribute {
        didSet {
            valueLabels.removeViewsStartingAt(0)
            if valueLabelPosition != .notAnAttribute {
                for i in 0 ..< thumbViews.count {
                    addValueLabel(i)
                }
            }
        }
    }
    
    public var orientation: NSLayoutConstraint.Axis = .horizontal {
        didSet {
            setupOrientation()
            invalidateIntrinsicContentSize()
            repositionThumbViews()
        }
    }
    
    public var valueLabelFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumIntegerDigits = 1
        formatter.roundingMode = .halfEven
        return formatter
    }()
    
        //This property is used to enable/disable slider for a while.
    public var isLocked: Bool = false {
        willSet {
            panGestureView.isUserInteractionEnabled = !newValue
            let colorToBeSet = newValue ? SliderStateColor.disabledStateColor : self.sliderMode.color
            shapeLayer.strokeColor = colorToBeSet.cgColor
            
            fanStepLayer.strokeColor = newValue ? SliderStateColor.disabledStateColor.cgColor : UIColor.white.cgColor
            if sliderMode == .auto {
                if newValue {
                    thumbViews.first?.tintColor = colorToBeSet
                    thumbViews.last?.tintColor = colorToBeSet
                    upperLayer.strokeColor = colorToBeSet.cgColor
                    lowerLayer.strokeColor = colorToBeSet.cgColor
                } else {
                    thumbViews.first?.tintColor = orientation == .horizontal ? colorCooling : colorHeating
                    thumbViews.last?.tintColor = orientation == .horizontal ? colorHeating :  colorCooling
                    
                    lowerLayer.strokeColor = colorHeating.cgColor
                    upperLayer.strokeColor = colorCooling.cgColor
                }
            } else {
                thumbViews.forEach({$0.tintColor = colorToBeSet})
            }
            
                // START: If User has set autounlock time interval, then resetting this value to true after scheduled time
            if newValue && unlockInterval > 0 {
                unlockAfter(interval: unlockInterval)
            } else if unlockInterval > 0 {
                unlockTimer?.invalidate()
            }
                // END: If User has set autounlock time interval, then resetting this value to true after scheduled time
        }
    }
    
        // This property is used to Hide/Show the ghostBubble overlay.
    public var disableGhostBubble: Bool = true {
        willSet {
            lblGhostBuble.isHidden = newValue
        }
    }
    
    public var colorHeating: UIColor {
        return orientation == .vertical ? SliderStateColor.heatingStateColor : SliderStateColor.coolingStateColor
    }
    
    var colorCooling: UIColor {
        return orientation == .horizontal ? SliderStateColor.heatingStateColor : SliderStateColor.coolingStateColor
    }
    
        // MARK: - Slider value change handler
        // Slider value change handler
    public var sliderValueChangeHandler:((_ heatingVal: Int?, _ coolingVal: Int?, _ isHeatingThumbDragged: Bool?) -> Void)?
    
        // Slider value change handler
    public var fanSpeedChangeHandler:((_ currentIndex: Int) -> Void)?
    
    public var autoUnlockHandler: ((_ isUnlocked: Bool) -> Void)?
    
        // MARK: - Initialiser
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    public func initCommon(direction: NSLayoutConstraint.Axis, sliderMode: SliderMode, minValue: CGFloat, maxValue: CGFloat) {
        setup()
        self.sliderMode = sliderMode
        orientation = direction
        minimumValue = minValue
        maximumValue = maxValue
        self.isLocked = false   // By Default, timer will be unlocked.
    }
    
        /// Fan Mode Slider Initialisation
        ///
        /// - Parameters:
        ///   - sliderMode: 'Fan' mode
        ///   - fanSpeed: Set init Speed of Fan
    /* func initFanSlider(fanSpeed:FanSpeed = .Medium) {
     
     initCommon(direction: .vertical, sliderMode: .fan, minValue: 0.0, maxValue: 100)
     self.fanSpeed = fanSpeed
     snapStepSize = (maximumValue / CGFloat(FanSpeed.totalSteps))
     let currentVal = maximumValue - ((maximumValue / CGFloat(FanSpeed.totalSteps)) * CGFloat(fanSpeed.index))
     value = [currentVal]
     } */
    
    public func initFanSliderForModes(fanModes modes: [String], currentSpeedindex: Int) {
        arrFanMode = modes.reversed()
        initCommon(direction: .vertical, sliderMode: .fan, minValue: 0.0, maxValue: 100)
        currentFanSpeed = currentSpeedindex > modes.count ? modes.count : currentSpeedindex    // Consider highest value if currentSpeed crosses the max limit
    }
    
        /// Initialising Slider for Cooling/Heating Mode (Vertical or Horizontal) with Minimum-Maximum and current value
        ///
        /// - Parameters:
        ///   - position: slider Direction - Horizontal or Vertical
        ///   - sliderMode: Heating/Cooling mode
        ///   - minValue: Minimum temperature value
        ///   - maxValue: Maximum temperature value
        ///   - defaultValue: current temperature value
    public func initSlider(forSliderDirection position: NSLayoutConstraint.Axis, sliderMode: SliderMode, minValue: CGFloat = 0, maxValue: CGFloat = 100, defaultValue: CGFloat = 0, isGeoFencing: Bool = false) {
        
        initCommon(direction: position, sliderMode: sliderMode, minValue: minValue, maxValue: maxValue)
        value = [defaultValue]
        snapStepSize = 1
        self.isGeoFencing = isGeoFencing
            // Add Ghost Bubble
        self.addGhostBubble()
    }
    
        /// Initialising Auto mode slider
        ///
        /// - Parameters:
        ///   - position: Slider Direction (Horizontal or Vertical)
        ///   - minValue: Slider MiniMum Value
        ///   - maxValue: Slider MaxiMum Value
        ///   - coolingValue: Current Cooling value
        ///   - heatingValue: Current Heating value
        ///   - deadBand: Deadband value
    public func initAutoSlider(forSliderDirection position: NSLayoutConstraint.Axis, minValue: CGFloat = 0, maxValue: CGFloat = 100, heatMaxVal: CGFloat = 90, coolMinVal: CGFloat = 52, coolingValue: CGFloat = 0, heatingValue: CGFloat = 0, deadBand: CGFloat) {
        
        initCommon(direction: position, sliderMode: .auto, minValue: minValue, maxValue: maxValue)
        value = [heatingValue, coolingValue]
        thumbCount = 2
        snapStepSize = 1
        self.heatMaxValue = heatMaxVal
        self.coolMinValue = coolMinVal
        self.deadBand = deadBand
            // Add Ghost Bubble
        self.addGhostBubble()
    }
    
        // MARK: - DeInit
    deinit {
        print("Slider deinit")
        unlockTimer?.invalidate()
    }
    
        // MARK: - Setup
    public func setup() {
        trackView.backgroundColor = .yellow
        slideView.backgroundColor = .purple
        slideView.layoutMargins = .zero
        self.valueLabelPosition = .right
        setupOrientation()
        
            // Add PanGesture and TapGesture to handle dragging and Tapping events on slider
        addConstrainedSubview(panGestureView)
        for edge: NSLayoutConstraint.Attribute in [.top, .bottom, .left, .right] {
            constrain(panGestureView, at: edge, diff: -edge.inwardSign * margin)
        }
        setupPanGesture()
        setupTapGesture()
    }
    
    public func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        tapGesture.numberOfTapsRequired = 1
        panGestureView.addGestureRecognizer(tapGesture)
    }
    
    public func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didDrag(_:)))
        panGestureView.addGestureRecognizer(panGesture)
    }
    
    public func setupOrientation() {
        
        _ = orientation == .vertical ? ThumbImageName.verticalImageName : ThumbImageName.horizontalImageName
        self.thumbImage = defaultThumbImage
        
            // Removing all the subviews and their constraints and adding them again according to orientation
        trackView.removeFromSuperview()
        trackView.removeConstraints(trackView.constraints)
        slideView.removeFromSuperview()
        
        self.shapeLayer.removeFromSuperlayer()
        self.fanStepLayer.removeFromSuperlayer()
        lowerLayer.removeFromSuperlayer()
        upperLayer.removeFromSuperlayer()
            //        self.lblGhostBuble.removeFromSuperview()
        thumbViews.forEach({$0.tintColor = sliderMode.color})
        
            // Calculating the margin of thumbview according to imageSize and added margin accordingly
        let thumbSize = thumbImage?.size ?? CGSize(width: 2, height: 2)
        let thumbDiameter = orientation == .vertical ? thumbSize.height : thumbSize.width
        let halfThumb = thumbDiameter / 2 - 1
        
        switch orientation {
                
            case .vertical:
                    // Add Track view first with top-bottom and center constraint
                addConstrainedSubview(trackView, constrain: .top, .bottom, .centerX)
                trackView.constrain(.width, to: trackWidth)
                
                    // Add Slideview in trackview
                trackView.addConstrainedSubview(slideView, constrain: .left, .right)
                
                trackView.constrain(slideView, at: .top, ratio: 1, relation: .equal)
                trackView.constrain(slideView, at: .bottom, ratio: 1, relation: .equal)
                
            case .horizontal:
                let centerAttribute: NSLayoutConstraint.Attribute
                if #available(iOS 12, *) {
                    centerAttribute = .centerY // iOS 12 doesn't like .leftMargin, .rightMargin
                } else {
                    centerAttribute = .centerYWithinMargins
                }
                addConstrainedSubview(trackView, constrain: .left, .right, centerAttribute)
                trackView.constrain(.height, to: trackWidth)
                if #available(iOS 12, *) {
                    trackView.addConstrainedSubview(slideView, constrain: .top, .bottom) // iOS 12 β doesn't like .leftMargin, .rightMargin
                } else {
                    trackView.addConstrainedSubview(slideView, constrain: .top, .bottom)
                }
                
                trackView.constrain(slideView, at: .left, diff: halfThumb, ratio: 1, relation: .equal)
                trackView.constrain(slideView, at: .right, diff: -halfThumb, ratio: 1, relation: .equal)
                
            @unknown default:
                fatalError()
        }
        setupTrackLayoutMargins()
    }
    
    public func setupTrackLayoutMargins() {
        let thumbSize = thumbImage?.size ?? CGSize(width: 2, height: 2)
        let thumbDiameter = orientation == .vertical ? thumbSize.height : thumbSize.width
        let halfThumb = thumbDiameter / 2 - 3 // 1 pixel for semi-transparent boundary
        
        if orientation == .vertical {
            trackView.layoutMargins = UIEdgeInsets(top: halfThumb, left: 0, bottom: halfThumb, right: 0)
            
            let lineStartPoint = CGPoint(x: 0, y: 0)
            let lineEndPoint = CGPoint(x: 0, y: self.frame.height)
            
            self.drawDottedLine(start: lineStartPoint, end: lineEndPoint, view: slideView)
            if sliderMode == .auto {
                addAutoColorLayer(view: slideView, start: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: self.frame.height))
            }
        } else {
            trackView.layoutMargins = UIEdgeInsets(top: 0, left: halfThumb, bottom: 0, right: halfThumb)
            let lineStartPoint = CGPoint(x: halfThumb, y: 0)
            let lineEndPoint = CGPoint(x: self.frame.width - (halfThumb), y: 0 )
            
            self.drawDottedLine(start: lineStartPoint, end: lineEndPoint, view: trackView)
            if sliderMode == .auto {
                addAutoColorLayer(view: trackView, start: lineStartPoint, endPoint: lineEndPoint)
            }
        }
    }
    
    public func lineDashPattern() -> [NSNumber] {
        return [0.4, dotRadius * 1.1667] as [NSNumber]    // 1st parameter will be radius and 2nd will be spacing between two dots
                                                          // Calculation : Considering 100% length of main layer, 0.4% will get occupied for drawing the dot, the next remaining % will be empty space
                                                          // e.g. 0.4 will be dot radius, 7 will be the empty space and again 0.4 radius' dot will get drawn and so on...
    }
        // MARK: - Draw dotted line
        /// Draw dotted line between two points
        ///
        /// - Parameters:
        ///   - p0: Starting Point
        ///   - p1: Ending Point
        ///   - view: Parent view on which line needs to be drawn
    public func drawDottedLine(start p0: CGPoint, end p1: CGPoint, view: UIView) {
        
        shapeLayer.strokeColor = sliderMode.color.cgColor
        
        if sliderMode == .geoFencing {
            shapeLayer.lineWidth = 2
            shapeLayer.lineDashPattern = [1, 0]
            let path = CGMutablePath()
            path.addLines(between: [p0, p1])
            shapeLayer.path = path
            view.layer.addSublayer(shapeLayer)
        } else {
            let dot: NSNumber = NSNumber(value: dotRadius)
            shapeLayer.lineWidth = CGFloat(dot.floatValue)
            shapeLayer.lineDashPattern = lineDashPattern()
            shapeLayer.lineCap = .round // Capping the line style as round to draw a circle
            let path = CGMutablePath()
            path.addLines(between: [p0, p1])
            shapeLayer.path = path
            view.layer.addSublayer(shapeLayer)
            
                // START : For Fan Mode, adding another layer for displaying Fan Speed points at calculated interval
            if sliderMode == .fan {
                let totalSize = p1.y - p0.y
                    // START : Calculate stepSize according to number of modes
                let length = (totalSize / CGFloat(arrFanMode.count - 1)) // This length will be the gap between two modes.
                let dotDiameter = (length * 0.01)   // To add dot at starting position of gap, 1% area will draw the dot
                let spaceDiameter = (length * 0.98) // After adding the dot, remaining path will have empty space. Considering only 99% of available space because the same process will get applied for the next mode (1st space will be occupied for dot and remaining will be for empty space)
                                                    // END : Calculate stepSize according to number of modes
                
                fanStepLayer.strokeColor = fanStepColor
                fanStepLayer.lineWidth = CGFloat(dot.floatValue * 1.5)
                fanStepLayer.lineDashPattern = [dotDiameter, spaceDiameter] as [NSNumber]
                fanStepLayer.lineCap = .round
                let pathDot = CGMutablePath()
                pathDot.addLines(between: [p0, p1])
                fanStepLayer.path = pathDot
                shapeLayer.addSublayer(fanStepLayer)
            }
                // END : For Fan Mode, adding another layer for displaying Fan Speed points at calculated interval
        }
    }
    
    public func addAutoColorLayer(view: UIView, start: CGPoint, endPoint: CGPoint) {
        
        let dot: NSNumber = NSNumber(value: dotRadius)
        lowerLayer.lineWidth = CGFloat(dot.floatValue)
        lowerLayer.lineDashPattern = lineDashPattern()
        lowerLayer.strokeColor = colorHeating.cgColor
        lowerLayer.lineCap = .round
        
        let totalSize = orientation == .horizontal ? endPoint.x - start.x : endPoint.y - start.y
        let gapSize = (dot.floatValue * 1.1667) + 0.4
        let extraPix = totalSize.remainder(dividingBy: CGFloat(gapSize))
        
            // Reducing 0.5px width extra for handling layer alignment in Horizontal direction.
        let lowerStartPoint = orientation == .horizontal ? CGPoint(x: endPoint.x - CGFloat(extraPix - 0.5), y: endPoint.y) :
        CGPoint(x: endPoint.x, y: endPoint.y - CGFloat(extraPix - 0.5))
        let path = CGMutablePath()
        path.addLines(between: [lowerStartPoint, start])
        lowerLayer.path = path
        lowerLayer.strokeEnd = 0
        view.layer.addSublayer(lowerLayer)
        
        upperLayer.lineWidth = CGFloat(dot.floatValue)
        upperLayer.lineDashPattern = lineDashPattern()
        upperLayer.strokeColor = colorCooling.cgColor
        upperLayer.lineCap = .round
        let pathUpper = CGMutablePath()
        pathUpper.addLines(between: [start, endPoint])
        upperLayer.path = pathUpper
        upperLayer.strokeEnd = 0
        view.layer.addSublayer(upperLayer)
    }
    
        // MARK: - Render slideview components
    public func addThumbView() {
        let i = thumbViews.count
        let thumbView = UIImageView(image: thumbImage)
        thumbViews.append(thumbView)
        if sliderMode == .auto {
            thumbViews.first?.tintColor = orientation == .horizontal ? colorCooling : colorHeating
            thumbViews.last?.tintColor = orientation == .horizontal ? colorHeating :  colorCooling
        } else {
            thumbView.tintColor = sliderMode.color
        }
        if orientation == .vertical {
            slideView.addConstrainedSubview(thumbView, constrain: .trailing)
            slideView.constraints.first(where: {$0.firstAttribute == .trailing})?.isActive = false
            
            slideView.constrain(thumbView, at: .right, diff: 18, ratio: 1, relation: .equal)
            
            if sliderMode == .fan {
                lblGhostBuble.isHidden = true
            } else {
                lblGhostBuble.isHidden = false
            }
        } else {
            lblGhostBuble.isHidden = false
            slideView.addConstrainedSubview(thumbView, constrain: .bottom)
            slideView.constrain(thumbView, at: .bottom, diff: -22, ratio: 1, relation: .equal)
        }
        
        positionThumbView(i)
        addValueLabel(i)
    }
    
    public func addValueLabel(_ i: Int) {
        
        guard valueLabelPosition != .notAnAttribute else { return }
        let valueLabel = UITextField()
        valueLabel.borderStyle = .none
        valueLabel.textColor = sliderMode == .geoFencing ? .black : .black
        valueLabel.font = UIFont.systemFont(ofSize: 15)
        slideView.addSubview(valueLabel)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.accessibilityIdentifier = "Thumb" + "\(i)"
        let thumbView = thumbViews[i]
        if orientation == .horizontal {
            slideView.constrain(valueLabel, at: valueLabelPosition.perpendicularCenter, diff: -44, ratio: 1, relation: .equal)
        } else {
            slideView.constrain(valueLabel, at: valueLabelPosition.perpendicularCenter, to: thumbView)
        }
        
        slideView.constrain(
            valueLabel, at: .centerX,
            to: thumbView, at: .centerX,
            diff: orientation == .horizontal ? 2 : -2
        )
        valueLabels.append(valueLabel)
        updateValueLabel(i)
    }
    
    public func addGhostBubble() {
        lblGhostBuble.frame = .init(x: 0, y: 0, width: 50, height: 50)
        lblGhostBuble.backgroundColor = self.sliderMode.color
        lblGhostBuble.textColor = .white
        lblGhostBuble.clipsToBounds = true
        lblGhostBuble.alpha = 0
        lblGhostBuble.isUserInteractionEnabled = false
        lblGhostBuble.textAlignment = .center
        lblGhostBuble.font = UIFont.systemFont(ofSize: 18)
        lblGhostBuble.layer.cornerRadius = lblGhostBuble.frame.size.width / 2
        addSubview(lblGhostBuble)
    }
    
        // MARK: - Update Values
    public func updateSliderValues(currentCoolVal: CGFloat, currentHeatVal: CGFloat, deadBand: CGFloat) {
        if sliderMode == .auto && value.count > 1 {
            self.deadBand = deadBand
            value[0] = currentHeatVal
            value[1] = currentCoolVal
        }
    }
    
    public func updateHeating(newValue: Int) {
        if (sliderMode == .auto) {
            let floatVal = CGFloat(newValue)
            if floatVal <= minimumValue {
                value[0] = minimumValue
            } else if floatVal + deadBand >= maximumValue {
                if orientation == .vertical {
                    value[1] = maximumValue
                    value[0] = maximumValue - deadBand
                } else {
                    value[0] = value[1] - deadBand
                }
            } else {
                if orientation == .vertical {
                    value[0] = floatVal
                    draggedThumbIndex = 0
                    updateThumbViewsAccordingToDeadBand()
                } else {
                    if floatVal + deadBand <= value[1] {
                        value[0] = floatVal
                    } else {
                        value[0] = value[1] - deadBand
                    }
                }
            }
            
        } else if sliderMode == .heating {
            if value.count > 0 {
                if CGFloat(newValue) >= minimumValue && CGFloat(newValue) <= maximumValue {
                    value = [CGFloat(newValue)]
                }
            }
        }
    }
    
    public func updateCooling(newValue: Int) {
        if (sliderMode == .auto) {
            let floatVal = CGFloat(newValue)
            if floatVal >= maximumValue {
                value[1] = maximumValue
            } else if floatVal - deadBand <= minimumValue {
                if orientation == .vertical {
                    value[0] = minimumValue
                    value[1] = minimumValue + deadBand
                } else {
                    value[1] = value[0] + deadBand
                }
            } else {
                if orientation == .vertical {
                    value[1] = floatVal
                    draggedThumbIndex = 1
                    updateThumbViewsAccordingToDeadBand()
                } else {
                    if floatVal - deadBand >= value[0] {
                        value[1] = floatVal
                    } else {
                        value[1] = value[0] + deadBand
                    }
                }
            }
        } else if sliderMode == .cooling {
            if value.count > 0 {
                if CGFloat(newValue) >= minimumValue && CGFloat(newValue) <= maximumValue {
                    value = [CGFloat(newValue)]
                }
            }
        }
    }
    
        /// change current value and update thumb according to new value
        ///
        /// - Parameters:
        ///   - newValue: new value
        ///   - type: type of slider (cooling or heating)
    public func changeCurrentValue(newValue: CGFloat, type: SliderMode) {
        if sliderMode == .auto {
            let currentIndex = type == .heating ? 0 : 1
            if newValue <= minimumValue && type == .heating { // For heating bottom thumb limit, New value not less then minimum value
                value[0] = minimumValue
            } else if newValue + deadBand >= maximumValue  && type == .heating { // For heating top limit
                if orientation == .vertical {
                    value[1] = maximumValue
                    value[0] = maximumValue - deadBand
                } else {
                    value[0] = value[1] - deadBand
                }
            } else if newValue >= maximumValue && type == .cooling { //For cooling top thumb limit
                value[1] = maximumValue
            } else if newValue - deadBand <= minimumValue && type == .cooling { //For cooling bottom limit
                if orientation == .vertical {
                    value[0] = minimumValue
                    value[1] = minimumValue + deadBand
                } else {
                    value[1] = value[0] + deadBand
                }
            } else {
                if orientation == .vertical { // Changing alternate thumb position and value based on current value
                    value[currentIndex] = newValue
                    draggedThumbIndex = currentIndex
                    updateThumbViewsAccordingToDeadBand()
                } else if type == .heating {
                    if newValue + deadBand <= value[1] {
                        value[0] = newValue
                    } else {
                        value[0] = value[1] - deadBand
                    }
                } else if type == .cooling {
                    if newValue - deadBand >= value[0] {
                        value[1] = newValue
                    } else {
                        value[1] = value[0] + deadBand
                    }
                }
            }
        } else if sliderMode == .cooling || sliderMode == .heating || sliderMode == .geoFencing { // For heating or cooling mode slider
            if value.count > 0 {
                if CGFloat(newValue) >= minimumValue && CGFloat(newValue) <= maximumValue {
                    value = [CGFloat(newValue)]
                }
            }
        }
    }
    
    public func repositionThumbViews() {
        thumbViews.forEach { $0.removeFromSuperview() }
        thumbViews = []
        valueLabels.forEach { $0.removeFromSuperview() }
        valueLabels = []
        adjustThumbCountToValueCount()
    }
    
        /// Add/Remove thumbs from superview according to available values in 'value' array
    public func adjustThumbCountToValueCount() {
        if value.count == thumbViews.count {
            return
        } else if value.count < thumbViews.count {
            thumbViews.removeViewsStartingAt(value.count)
            valueLabels.removeViewsStartingAt(value.count)
        } else { // add thumbViews
            for _ in thumbViews.count ..< value.count {
                addThumbView()
            }
        }
    }
    
        /// Auto unlocking slider after specified timeinterval. If Time Interval is 0, slider won't get enabled automatically
        ///
        /// - Parameter seconds: timeinterval after which slider will be auto unlocked
    public func setEnabledAutoUnlock(seconds: Double) {
        unlockInterval = seconds
    }
    
        /// Auto unlocking slider after mentioned time interval
        ///
        /// - Parameter seconds: Seconds after which timer operation will get executed
    public func unlockAfter(interval seconds: Double) {
        unlockTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] (timer) in
            self?.isLocked = false
            timer.invalidate()
            self?.autoUnlockHandler?(true)
        }
    }
    
        /// Updating Thumb bubble value according to dragged/tapped
        ///
        /// - Parameter thumbIndex: Index of thumbview which needs to be updated
    public func updateValueLabel(_ thumbIndex: Int) {
        let labelValue: CGFloat
        labelValue = value[thumbIndex]
        if sliderMode == .fan {
            let index = Int(maximumValue / snapStepSize) - Int((value[thumbIndex] / snapStepSize))
            if index < arrFanMode.count {
                valueLabels[thumbIndex].text = arrFanMode[index]
            } else {
                valueLabels[thumbIndex].text = arrFanMode.first
            }
        } else {
            let val = valueLabelFormatter.string(from: NSNumber(value: Int(labelValue)))
            valueLabels[thumbIndex].text = sliderMode == .geoFencing ? val?.appending(geoFencingUnit) : val
            
            if draggedThumbIndex >= 0 && draggedThumbIndex < valueLabels.count {
                lblGhostBuble.text = valueLabels[draggedThumbIndex].text
            }
        }
        
            // START: Calculate height/width (For Horizontal orientation, consider Height and For Vertical, consider Width) based on the text and render the UI accordingly
        if orientation == .horizontal {
                // Calculate height based on the text and render the UI accordingly
            let height = max(valueLabels[thumbIndex].text!.widthOfString(usingFont: valueLabels[thumbIndex].font!), 30)
            thumbViews[thumbIndex].constrain(.width, to: height + 10, ratio: 1, relation: .equal)
        } else {
            let width = max(valueLabels[thumbIndex].text!.widthOfString(usingFont: valueLabels[thumbIndex].font!), 20)
            thumbViews[thumbIndex].constrain(.width, to: width + 30, ratio: 1, relation: .equal)
        }
            // END: Calculate height/width (For Horizontal orientation, consider Height and For Vertical, consider Width) based on the text and render the UI accordingly
    }
    
        /// Updating value according to snapstep size (Rounding up the value)
    public func adjustValuesToStepAndLimits() {
        var adjusted = value //.sorted()
        for i in 0 ..< adjusted.count {
            let snapped = adjusted[i].rounded(snapStepSize)
            adjusted[i] = min(maximumValue, max(minimumValue, snapped))
        }
        
        isSettingValue = true
        value = adjusted
        isSettingValue = false
        
        for i in 0 ..< value.count {
            positionThumbView(i)
        }
    }
    
        /// Updating the thumbview position while dragging/tapping
        ///
        /// - Parameter index: index of the thumbview which needs to be repositioned
    public func positionThumbView(_ index: Int) {
        
        let thumbView = thumbViews[index]
        let thumbValue = value[index]
        slideView.removeFirstConstraint { $0.firstItem === thumbView && $0.firstAttribute == .center(in: orientation) }
        
            // Calculate the percentage of position for thumbValue
        let thumbRelativeDistanceToMax = (maximumValue - thumbValue) / (maximumValue - minimumValue)
            // START : Update Constraint according to orientation and calculated distance
        if orientation == .horizontal {
            if thumbRelativeDistanceToMax < 1 {
                if deadBand == 0 {
                    let signedGap = index == 0 ? 0.0045 : -0.0045
                    slideView.constrain(thumbView, at: .centerX, to: slideView, at: .right, ratio: CGFloat(1 - thumbRelativeDistanceToMax) - CGFloat(signedGap))
                } else {
                    slideView.constrain(thumbView, at: .centerX, to: slideView, at: .right, ratio: CGFloat(1 - thumbRelativeDistanceToMax))
                }
            } else {
                slideView.constrain(thumbView, at: .centerX, to: slideView, at: .left)
            }
        } else { // vertical orientation
            if thumbRelativeDistanceToMax.isNormal {
                if deadBand == 0 {
                    let signedGap = index == 0 ? 0.01 : -0.01
                    slideView.constrain(thumbView, at: .centerY, to: slideView, at: .bottom, ratio: CGFloat(thumbRelativeDistanceToMax) + CGFloat(signedGap))
                } else {
                    slideView.constrain(thumbView, at: .centerY, to: slideView, at: .bottom, ratio: CGFloat(thumbRelativeDistanceToMax))
                }
            } else {
                slideView.constrain(thumbView, at: .centerY, to: slideView, at: .top)
            }
        }
            // END : Update Constraint according to orientation and calculated distance
        
            // updating layer position according to drag direction.
        if sliderMode == .auto {
            self.drawStrokeForAutoSlider(atIndex: index)
        }
        
        updateGhostBubble()
    }
    
        /// update bubble position based on selected dragging thumb
    public func updateGhostBubble() {
        
            // Positioning the ghost bubble for the thumb which is currently getting dragged.
            // i.e. If lower thumb is dragged, then ghostbubble for it will get displayed
        if thumbViews.count > draggedThumbIndex && draggedThumbIndex >= 0 {
            let selectedThumb = thumbViews[draggedThumbIndex]
            
                // Getting Bubble center position based on Slider Orientation. For Vertical Orientation, considering track view's center and width to align bubble beside track view.
                // For Horizontal orientation, considering trackview center's y position and updating Ghostbubble's y-pos.
            let bubbleLoc = orientation == .vertical ? CGPoint(x: trackView.center.x - (selectedThumb.frame.width + lblGhostBuble.frame.width), y: selectedThumb.center.y + (self.lblGhostBuble.frame.width / 4) - 40) : CGPoint(x: selectedThumb.center.x + (self.lblGhostBuble.frame.width / 4), y: trackView.center.y - (selectedThumb.frame.height + (lblGhostBuble.frame.height * 1.25)))
            
            lblGhostBuble.backgroundColor = selectedThumb.tintColor
            /*if valueLabels.count > draggedThumbIndex {
             lblGhostBuble.text = valueLabels[draggedThumbIndex].text
             }*/
            UIView.animate(withDuration: 0.1) {
                self.slideView.updateConstraintsIfNeeded()
                self.lblGhostBuble.center = bubbleLoc
            }
        }
    }
    
        /// Render Autoslider layers according to index
        ///
        /// - Parameter index: index of layer
    public func drawStrokeForAutoSlider(atIndex index: Int) {
        
            // Disable stroke-end transition
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
            // Draw layer according to thumbIndex (Upper or Lower thumb) and direction
        if index == 0 {
            if orientation == .horizontal {
                upperLayer.strokeEnd = 1 - (maximumValue - (value[index])) / (maximumValue - minimumValue)//((value[i]) / maximumValue)
            } else {
                lowerLayer.strokeEnd = 1 - (maximumValue - (value[index])) / (maximumValue - minimumValue) //((value[i]) / maximumValue)
            }
        } else if index == 1 {
            if orientation == .vertical {
                upperLayer.strokeEnd = (maximumValue - (value[index])) / (maximumValue - minimumValue)//((value[i]) / maximumValue)
            } else {
                lowerLayer.strokeEnd = (maximumValue - (value[index])) / (maximumValue - minimumValue)//1 - ((value[i]) / maximumValue)
            }
        }
        
            // Disable stroke-end transition
        CATransaction.commit()
    }
    
        // MARK: - Override
    open override var intrinsicContentSize: CGSize {
        let thumbSize = (defaultThumbImage)?.size ?? CGSize(width: margin, height: margin)
        switch orientation {
            case .vertical:
                return CGSize(width: thumbSize.width + margin, height: UIView.noIntrinsicMetric)
            case .horizontal:
                return CGSize(width: UIView.noIntrinsicMetric, height: thumbSize.height + margin)
            @unknown default:
                fatalError()
        }
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isHidden || alpha == 0 { return nil }
        if clipsToBounds { return super.hitTest(point, with: event) }
        return panGestureView.hitTest(panGestureView.convert(point, from: self), with: event)
    }
}
