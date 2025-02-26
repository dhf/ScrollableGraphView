import UIKit

open class Plot {
    // The id for this plot. Used when determining which data to give it in the dataSource
    open var identifier: String!
    open var shouldShowLabels = false
    
    weak var graphViewDrawingDelegate: ScrollableGraphViewDrawingDelegate!
    
    // Animation Settings
    // ##################
    
    /// How long the animation should take. Affects both the startup animation and the animation when the range of the y-axis adapts to onscreen points.
    open var animationDuration: Double = 1.5
    
    open var adaptAnimationType_: Int {
        get { return adaptAnimationType.rawValue }
        set {
            if let enumValue = ScrollableGraphViewAnimationType(rawValue: newValue) {
                adaptAnimationType = enumValue
            }
        }
    }
    /// The animation style.
    open var adaptAnimationType = ScrollableGraphViewAnimationType.easeOut
    /// If adaptAnimationType is set to .Custom, then this is the easing function you would like applied for the animation.
    open var customAnimationEasingFunction: ((_ t: Double) -> Double)?
    
    // Labels
    // #####################

    /// The font to be used for the value label.
    open var labelFont = UIFont.systemFont(ofSize: 8)
    /// The colour of the value label font.
    open var labelColor = UIColor.black
    /// How far to offset the vertical position of the label.
    open var labelVerticalOffset: CGFloat = 0

    // Private Animation State
    // #######################
    
    private var currentAnimations = [GraphPointAnimation]()
    private var displayLink: CADisplayLink!
    private var previousTimestamp: CFTimeInterval = 0
    private var currentTimestamp: CFTimeInterval = 0
    
    private var graphPoints = [GraphPoint]()
    
    deinit {
        displayLink?.invalidate()
    }
    
    // MARK: Different plot types should implement:
    // ############################################
    
    func layers(forViewport viewport: CGRect) -> [ScrollableGraphViewDrawingLayer?] {
        return []
    }
    
    // MARK: Plot Animation
    // ####################
    
    // Animation update loop for co-domain changes.
    @objc dynamic private func animationUpdate() {
        let dt = timeSinceLastFrame()
        
        for animation in currentAnimations {
            
            animation.update(withTimestamp: dt)
            
            if animation.finished {
                dequeue(animation: animation)
            }
        }
        
        graphViewDrawingDelegate.updatePaths()
    }
    
    private func animate(point: GraphPoint, to position: CGPoint, withDelay delay: Double = 0) {
        let currentPoint = CGPoint(x: point.x, y: point.y)
        let animation = GraphPointAnimation(fromPoint: currentPoint, toPoint: position, forGraphPoint: point)
        animation.animationEasing = getAnimationEasing()
        animation.duration = animationDuration
        animation.delay = delay
        enqueue(animation: animation)
    }
    
    private func getAnimationEasing() -> (Double) -> Double {
        switch adaptAnimationType  {
        case .elastic:
            return Easings.easeOutElastic
        case .easeOut:
            return Easings.easeOutQuad
        case .custom:
            if let customEasing = customAnimationEasingFunction {
                return customEasing
            }
            else {
                fallthrough
            }
        default:
            return Easings.easeOutQuad
        }
    }

    private func updateDisplayLink(to value: Bool) {
        if currentAnimations.isEmpty {
            displayLink.isPaused = value
        }
    }
    
    private func enqueue(animation: GraphPointAnimation) {
        updateDisplayLink(to: false)
        currentAnimations.append(animation)
    }
    
    private func dequeue(animation: GraphPointAnimation) {
        if let index = currentAnimations.firstIndex(of: animation) {
            currentAnimations.remove(at: index)
        }
        updateDisplayLink(to: true)
    }
    
    internal func dequeueAllAnimations() {
        
        for animation in currentAnimations {
            animation.animationDidFinish()
        }
        
        currentAnimations.removeAll()
        displayLink.isPaused = true
    }
    
    private func timeSinceLastFrame() -> Double {
        if previousTimestamp == 0 {
            previousTimestamp = displayLink.timestamp
        } else {
            previousTimestamp = currentTimestamp
        }
        currentTimestamp = displayLink.timestamp
        return min(currentTimestamp - previousTimestamp, 0.032)
    }
    
    internal func startAnimations(forPoints pointsToAnimate: CountableRange<Int>,
                                  withData data: [Double],
                                  withStaggerValue stagger: Double) {
        animatePlotPointPositions(forPoints: pointsToAnimate, withData: data, withDelay: stagger)
    }
    
    internal func createPlotPoints(numberOfPoints: Int, range: (min: Double, max: Double)) {
        for i in 0 ..< numberOfPoints {
            let position = graphViewDrawingDelegate.calculatePosition(atIndex: i, value: range.min)
            graphPoints.append(GraphPoint(position: position))
        }
    }
    
    // When active interval changes, need to set the position for any NEWLY ACTIVATED points, otherwise
    // they will come on screen at the incorrect position.
    // Needs to be called when the active interval has changed and during initial setup.
    internal func setPlotPointPositions(forNewlyActivatedPoints newPoints: CountableRange<Int>, withData data: [Double]) {
        for i in newPoints.indices {
            // e.g.
            // indices: 10...20
            // data positions: 0...10 = // 0 to (end - start)
            let value = data[i - newPoints.startIndex]
            let newPosition = graphViewDrawingDelegate.calculatePosition(atIndex: i, value: value)
            graphPoints[i].x = newPosition.x
            graphPoints[i].y = newPosition.y
        }
    }
    
    // Same as a above, but can take an array with the indicies of the activated points rather than a range.
    internal func setPlotPointPositions(forNewlyActivatedPoints activatedPoints: [Int], withData data: [Double]) {
        var index = 0
        for activatedPointIndex in activatedPoints {
            let dataPosition = index
            let value = data[dataPosition]
            
            let newPosition = graphViewDrawingDelegate.calculatePosition(atIndex: activatedPointIndex, value: value)
            graphPoints[activatedPointIndex].x = newPosition.x
            graphPoints[activatedPointIndex].y = newPosition.y
            
            index += 1
        }
    }
    
    // When the range changes, we need to set the position for any VISIBLE points, either animating or setting directly
    // depending on the settings.
    // Needs to be called when the range has changed.
    internal func animatePlotPointPositions(forPoints pointsToAnimate: CountableRange<Int>, withData data: [Double], withDelay delay: Double) {
        // For any visible points, kickoff the animation to their new position after the axis' min/max has changed.
        var dataIndex = 0
        for pointIndex in pointsToAnimate {
            let newPosition = graphViewDrawingDelegate.calculatePosition(atIndex: pointIndex, value: data[dataIndex])
            let point = graphPoints[pointIndex]
            animate(point: point, to: newPosition, withDelay: Double(dataIndex) * delay)
            dataIndex += 1
        }
    }
    
    internal func setup() {
        displayLink = CADisplayLink(target: self, selector: #selector(animationUpdate))
        displayLink.add(to: .main, forMode: .common)
        displayLink.isPaused = true
    }
    
    internal func reset() {
        currentAnimations.removeAll()
        graphPoints.removeAll()
        displayLink?.invalidate()
        previousTimestamp = 0
        currentTimestamp = 0
    }
    
    internal func invalidate() {
        currentAnimations.removeAll()
        graphPoints.removeAll()
        displayLink?.invalidate()
    }
    
    internal func graphPoint(forIndex index: Int) -> GraphPoint {
        return graphPoints[index]
    }
}

@objc public enum ScrollableGraphViewAnimationType : Int {
    case easeOut
    case elastic
    case custom
}
