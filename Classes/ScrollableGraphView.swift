import UIKit

// MARK: - ScrollableGraphView
@IBDesignable
@objc open class ScrollableGraphView: UIScrollView, UIScrollViewDelegate, ScrollableGraphViewDrawingDelegate {
    
    // MARK: - Public Properties
    // Use these to customise the graph.
    // #################################
    
    // Fill Styles
    // ###########
    
    /// The background colour for the entire graph view, not just the plotted graph.
    @IBInspectable open var backgroundFillColor: UIColor = .white
    
    // Spacing
    // #######
    
    /// How far the "maximum" reference line is from the top of the view's frame. In points.
    @IBInspectable open var topMargin: CGFloat = 10
    /// How far the "minimum" reference line is from the bottom of the view's frame. In points.
    @IBInspectable open var bottomMargin: CGFloat = 10
    /// How far the first point on the graph should be placed from the left hand side of the view.
    @IBInspectable open var leftmostPointPadding: CGFloat = 50
    /// How far the final point on the graph should be placed from the right hand side of the view.
    @IBInspectable open var rightmostPointPadding: CGFloat = 50
    /// How much space should be between each data point.
    @IBInspectable open var dataPointSpacing: CGFloat = 40
    
    @IBInspectable var direction_: Int {
        get { return direction.rawValue }
        set {
            if let enumValue = ScrollableGraphViewDirection(rawValue: newValue) {
                direction = enumValue
            }
        }
    }
    /// Which side of the graph the user is expected to scroll from.
    open var direction = ScrollableGraphViewDirection.leftToRight
    
    // Graph Range
    // ###########
    
    /// Forces the graph's minimum to always be zero. Used in conjunction with shouldAutomaticallyDetectRange or shouldAdaptRange, if you want to force the minimum to stay at 0 rather than the detected minimum.
    @IBInspectable open var shouldRangeAlwaysStartAtZero: Bool = false
    /// The minimum value for the y-axis. This is ignored when shouldAutomaticallyDetectRange or shouldAdaptRange = true
    @IBInspectable open var rangeMin: Double = 0
    /// The maximum value for the y-axis. This is ignored when shouldAutomaticallyDetectRange or shouldAdaptRange = true
    @IBInspectable open var rangeMax: Double = 100
    
    // Adapting & Animations
    // #####################
    
    /// Whether or not the y-axis' range should adapt to the points that are visible on screen. This means if there are only 5 points visible on screen at any given time, the maximum on the y-axis will be the maximum of those 5 points. This is updated automatically as the user scrolls along the graph.
    @IBInspectable open var shouldAdaptRange: Bool = false
    /// If shouldAdaptRange is set to true then this specifies whether or not the points on the graph should animate to their new positions. Default is set to true.
    @IBInspectable open var shouldAnimateOnAdapt: Bool = true
    
    /// Whether or not the graph should animate to their positions when the graph is first displayed.
    @IBInspectable open var shouldAnimateOnStartup: Bool = true
    
    // Reference Line Settings
    // #######################
    
    var referenceLines: ReferenceLines?
    
    // MARK: - Private State
    // #####################
    
    private var isInitialSetup = true
    private var isCurrentlySettingUp = false
    
    private var viewportWidth: CGFloat = 0 {
        didSet { if oldValue != viewportWidth { viewportDidChange() } }
    }
    private var viewportHeight: CGFloat = 0 {
        didSet { if oldValue != viewportHeight { viewportDidChange() } }
    }
    
    private var totalGraphWidth: CGFloat = 0
    private var offsetWidth: CGFloat = 0
    
    // Graph Line
    private var zeroYPosition: CGFloat = 0
    
    // Graph Drawing
    private var drawingView = UIView()
    private var plots = [Plot]()
    
    // Reference Lines
    private var referenceLineView: ReferenceLineDrawingView?
    
    // Labels
    private var labelsView = UIView()
    private var labelPool = LabelPool()
    private var plotLabelPool = [LabelPool]()

    // Data Source
    weak open var dataSource: ScrollableGraphViewDataSource? {
        didSet {
            if !plots.isEmpty {
                reload()
            }
        }
    }
    
    // Active Points & Range Calculation
    private var previousActivePointsInterval = -1 ..< -1
    private var activePointsInterval = -1 ..< -1 {
        didSet {
            if !isCurrentlySettingUp && oldValue != activePointsInterval {
                activePointsDidChange()
            }
        }
    }
    
    private var range: (min: Double, max: Double) = (0, 100) {
        didSet {
            if !isCurrentlySettingUp && oldValue != range {
                rangeDidChange()
            }
        }
    }
    
    // MARK: - INIT, SETUP & VIEWPORT RESIZING
    // #######################################
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public init(frame: CGRect, dataSource: ScrollableGraphViewDataSource) {
        self.dataSource = dataSource
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        for plot in plots {
            plot.invalidate()
        }
    }
    
    // You can change how you want the graph to appear in interface builder here.
    // This ONLY changes how it appears in interface builder, you will still need
    // to setup the graph properly in your view controller for it to change in the
    // actual application.
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        dataSource = self as? ScrollableGraphViewDataSource
        shouldAnimateOnStartup = false
        
        // Customise how the reference lines look in IB
        addReferenceLines(referenceLines: ReferenceLines())
    }
    
    private func setup() {
        clipsToBounds = true
        isCurrentlySettingUp = true
        
        // 0.
        // Save the viewport, that is, the size of the rectangle through which we view the graph.
        
        viewportWidth = frame.width
        viewportHeight = frame.height

        let viewport = CGRect(origin: .zero,
                              size: CGSize(width: viewportWidth, height: viewportHeight))
        
        // 1.
        // Add the subviews we will use to draw everything.
        
        // Add the drawing view in which we draw all the plots.
        drawingView = UIView(frame: viewport)
        drawingView.backgroundColor = backgroundFillColor
        addSubview(drawingView)
        
        // Add the x-axis labels view.
        insertSubview(labelsView, aboveSubview: drawingView)
        
        // 2.
        // Calculate the total size of the graph, need to know this for the scrollview.
        
        // Calculate the drawing frames
        let numberOfDataPoints = dataSource?.numberOfPoints() ?? 0
        totalGraphWidth = graphWidth(forNumberOfDataPoints: numberOfDataPoints)
        contentSize = CGSize(width: totalGraphWidth, height: viewportHeight)
        
        // Scrolling direction.
        
        #if TARGET_INTERFACE_BUILDER
            offsetWidth = 0
        #else
            if case .rightToLeft = direction {
                offsetWidth = contentSize.width - viewportWidth
            } else { // Otherwise start of all the way to the left.
                offsetWidth = 0
            }
        #endif
        
        // Set the scrollview offset.
        contentOffset.x = offsetWidth
        
        // 3.
        // Calculate the points that we will be able to see when the view loads.
        
        let initialActivePointsInterval = calculateActivePointsInterval()
        
        // 4.
        // Add the plots to the graph, we need these to calculate the range.

        while let plot = queuedPlots.dequeue() {
            addPlotToGraph(plot: plot, activePointsInterval: initialActivePointsInterval)
        }
        
        // 5.
        // Calculate the range for the points we can actually see.
        
        #if TARGET_INTERFACE_BUILDER
            range = (min: rangeMin, max: rangeMax)
        #else
            // Need to calculate the range across all plots to get the min and max for all plots.
            if shouldAdaptRange { // This overwrites anything specified by rangeMin and rangeMax
                range = calculateRange(forActivePointsInterval: initialActivePointsInterval)
            }
            else {
                range = (min: rangeMin, max: rangeMax) // just use what the user specified instead.
            }
        #endif
        
        // If the graph was given all 0s as data, we can't use a range of 0->0, so make sure we have a sensible range at all times.
        if range == (0, 0) {
            range = (min: 0, max: rangeMax)
        }
        
        // 6.
        // Add the reference lines, can only add this once we know the range.

        if referenceLines != nil {
            addReferenceViewDrawingView()
        }
        
        // 7.
        // We're now done setting up, update the offsets and change the flag.
        
        updateOffsetWidths()
        isCurrentlySettingUp = false
        
        // Set the first active points interval. These are the points that are visible when the view loads.
        activePointsInterval = initialActivePointsInterval
    }
    
    // TODO in 4.1: Plot layer ordering.
    // TODO in 4.1: Plot removal.
    private func addDrawingLayersForPlots(inViewport viewport: CGRect) {
        for plot in plots {
            addSubLayers(layers: plot.layers(forViewport: viewport))
        }
    }
    
    private func addSubLayers(layers: [ScrollableGraphViewDrawingLayer?]) {
        for layer in layers.lazy.compactMap({ $0 }) {
            drawingView.layer.addSublayer(layer)
        }
    }
    
    private func addReferenceViewDrawingView() {
        guard let referenceLines = referenceLines else {
            // We can want to add this if the settings arent nil.
            return
        }
        let viewport = CGRect(origin: .zero,
                              size: CGSize(width: viewportWidth, height: viewportHeight))
        if referenceLines.shouldShowReferenceLines, let font = referenceLines.dataPointLabelFont  {
            var referenceLineBottomMargin = bottomMargin
            
            // Have to adjust the bottom line if we are showing data point labels (x-axis).
            if(referenceLines.shouldShowLabels && referenceLines.dataPointLabelFont != nil) {
                referenceLineBottomMargin += font.pointSize + referenceLines.dataPointLabelTopMargin + referenceLines.dataPointLabelBottomMargin
            }
            
            referenceLineView?.removeFromSuperview()
            let newView = ReferenceLineDrawingView(
                frame: viewport,
                topMargin: topMargin,
                bottomMargin: referenceLineBottomMargin,
                referenceLineColor: referenceLines.referenceLineColor,
                referenceLineThickness: referenceLines.referenceLineThickness,
                referenceLineSettings: referenceLines
            )

            referenceLineView = newView
            newView.set(range: self.range)
            addSubview(newView)
        }
    }
    
    // If the view has changed we have to make sure we're still displaying the right data.
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        // while putting the view on the IB, we may get calls with frame too small
        // if frame height is too small we won't be able to calculate zeroYPosition
        // so make sure to proceed only if there is enough space
        var availableGraphHeight = frame.height
        availableGraphHeight = availableGraphHeight - topMargin - bottomMargin
        
        if let referenceLines = referenceLines,
           referenceLines.shouldShowLabels,
           let font = referenceLines.dataPointLabelFont {
            availableGraphHeight -= (font.pointSize + referenceLines.dataPointLabelTopMargin + referenceLines.dataPointLabelBottomMargin)
        }
        
        if availableGraphHeight > 0 {
            updateUI()
        }
    }
    
    private func updateUI() {
        // Make sure we have data, if don't, just get out. We can't do anything without any data.
        guard let dataSource = dataSource, dataSource.numberOfPoints() > 0 else { return }
        
        if isInitialSetup {
            setup()
            
            if shouldAnimateOnStartup {
                startAnimations(withStaggerValue: 0.15)
            }
            
            // We're done setting up.
            isInitialSetup = false
        }
            // Otherwise, the user is just scrolling and we just need to update everything.
        else {
            // Needs to update the viewportWidth and viewportHeight which is used to calculate which
            // points we can actually see.
            viewportWidth = frame.width
            viewportHeight = frame.height
            
            // If the scrollview has scrolled anywhere, we need to update the offset
            // and move around our drawing views.
            offsetWidth = contentOffset.x
            updateOffsetWidths()
            
            // Recalculate active points for this size.
            // Recalculate range for active points.
            let newActivePointsInterval = calculateActivePointsInterval()
            previousActivePointsInterval = activePointsInterval
            activePointsInterval = newActivePointsInterval
            
            // If adaption is enabled we want to
            if shouldAdaptRange {
                // TODO: This is currently called every single frame...
                // We need to only calculate the range if the active points interval has changed!
                #if !TARGET_INTERFACE_BUILDER
                    range = calculateRange(forActivePointsInterval: newActivePointsInterval)
                #endif
            }
        }
    }
    
    private func updateOffsetWidths() {
        drawingView.frame.origin.x = offsetWidth
        drawingView.bounds.origin.x = offsetWidth
        
        updateOffsetsForGradients(offsetWidth: offsetWidth)
        
        referenceLineView?.frame.origin.x = offsetWidth
    }
    
    private func updateOffsetsForGradients(offsetWidth: CGFloat) {
        drawingView.layer.sublayers?.lazy
            .compactMap { $0 as? GradientDrawingLayer }
            .forEach { $0.offset = offsetWidth }
    }
    
    private func updateFrames() {
        // Drawing view needs to always be the same size as the scrollview.
        drawingView.frame.size.width = viewportWidth
        drawingView.frame.size.height = viewportHeight
        
        // Gradient should extend over the entire viewport
        updateFramesForGradientLayers(viewportWidth: viewportWidth, viewportHeight: viewportHeight)
        
        // Reference lines should extend over the entire viewport
        referenceLineView?.set(viewportWidth: viewportWidth, viewportHeight: viewportHeight)
        
        contentSize.height = viewportHeight
    }
    
    private func updateFramesForGradientLayers(viewportWidth: CGFloat, viewportHeight: CGFloat) {
        drawingView.layer.sublayers?.lazy
            .compactMap { $0 as? GradientDrawingLayer }
            .forEach {
                $0.frame.size.width = viewportWidth
                $0.frame.size.height = viewportHeight
            }
    }
    
    // MARK: - Public Methods
    // ######################
    
    public func addPlot(plot: Plot) {
        // If we aren't setup yet, save the plot to be added during setup.
        if isInitialSetup {
            enqueuePlot(plot)
        }
        // Otherwise, just add the plot directly.
        else {
            addPlotToGraph(plot: plot, activePointsInterval: activePointsInterval)
        }
    }
    
    public func addReferenceLines(referenceLines: ReferenceLines) {
        // If we aren't setup yet, just save the reference lines and the setup will take care of it.
        if isInitialSetup {
            self.referenceLines = referenceLines
        }
        // Otherwise, add the reference lines, reload everything.
        else {
            addReferenceLinesToGraph(referenceLines: referenceLines)
        }
    }
    
    // Limitation: Can only be used when reloading the same number of data points!
    public func reload() {
        stopAnimations()
        rangeDidChange()
        updateUI()
        updatePaths()
        updateLabelsForCurrentInterval()
    }
    
    // The functions for adding plots and reference lines need to be able to add plots
    // both before and after the graph knows its viewport/size. 
    // This needs to be the case so we can use it in interface builder as well as 
    // just adding it programatically.
    // These functions add the plots and reference lines to the graph.
    // The public functions will either save the plots and reference lines (in the case
    // don't have the required viewport information) or add it directly to the graph
    // (the case where we already know the viewport information).
    private func addPlotToGraph(plot: Plot, activePointsInterval: CountableRange<Int>) {
        plot.graphViewDrawingDelegate = self
        plots.append(plot)
        plotLabelPool.append(LabelPool())
        initPlot(plot: plot, activePointsInterval: activePointsInterval)
        startAnimations(withStaggerValue: 0.15)
    }
    
    private func addReferenceLinesToGraph(referenceLines: ReferenceLines) {
        self.referenceLines = referenceLines
        addReferenceViewDrawingView()
        updateLabelsForCurrentInterval()
    }
    
    private func initPlot(plot: Plot, activePointsInterval: CountableRange<Int>) {
        #if !TARGET_INTERFACE_BUILDER
            plot.setup() // Only init the animations for plots if we are not in IB
        #endif
        
        plot.createPlotPoints(numberOfPoints: dataSource!.numberOfPoints(), range: range) // TODO: removed forced unwrap
        
        // If we are not animating on startup then just set all the plot positions to their respective values
        if !shouldAnimateOnStartup {
            let dataForInitialPoints = getData(forPlot: plot, andActiveInterval: activePointsInterval)
            plot.setPlotPointPositions(forNewlyActivatedPoints: activePointsInterval, withData: dataForInitialPoints)
        }
        
        addSubLayers(layers: plot.layers(forViewport: currentViewport()))
    }

    private lazy var queuedPlots = SGVQueue<Plot>()
    
    private func enqueuePlot(_ plot: Plot) {
        queuedPlots.enqueue(element: plot)
    }

    // MARK: - Private Methods
    // #######################
    
    // MARK: Layout Calculations
    // #########################
    
    private func calculateActivePointsInterval() -> CountableRange<Int> {
        // Calculate the "active points"
        let min = Int(offsetWidth / dataPointSpacing)
        let max = Int((offsetWidth + viewportWidth) / dataPointSpacing)
        
        // Add and minus two so the path goes "off the screen" so we can't see where it ends.
        let minPossible = 0
        var maxPossible = 0
        
        if let numberOfPoints = dataSource?.numberOfPoints() {
            maxPossible = numberOfPoints - 1
        }
        
        let numberOfPointsOffscreen = 2
        
        let actualMin = clamp(value: min - numberOfPointsOffscreen, min: minPossible, max: maxPossible)
        let actualMax = clamp(value: max + numberOfPointsOffscreen, min: minPossible, max: maxPossible)
        
        return actualMin..<actualMax.advanced(by: 1)
    }
    
    // Calculate the range across all plots.
    private func calculateRange(forActivePointsInterval interval: CountableRange<Int>) -> (min: Double, max: Double) {
        // This calculates the range across all plots for the active points.
        // So the maximum will be the max of all plots, same goes for min.
        var ranges = [(min: Double, max: Double)]()
        
        for plot in plots {
            let rangeForPlot = calculateRange(forPlot: plot, forActivePointsInterval: interval)
            ranges.append(rangeForPlot)
        }
        
        let minOfRanges = min(ofAllRanges: ranges)
        let maxOfRanges = max(ofAllRanges: ranges)
        
        return (min: minOfRanges, max: maxOfRanges)
    }
    
    private func max(ofAllRanges ranges: [(min: Double, max: Double)]) -> Double {
        return ranges.lazy.map { $0.max }.max() ?? 0
    }
    
    private func min(ofAllRanges ranges: [(min: Double, max: Double)]) -> Double {
        return ranges.lazy.map { $0.min }.min() ?? 0
    }
    
    // Calculate the range for a single plot.
    private func calculateRange(forPlot plot: Plot, forActivePointsInterval interval: CountableRange<Int>) -> (min: Double, max: Double) {
        let dataForActivePoints = getData(forPlot: plot, andActiveInterval: interval)
        
        // We don't have any active points, return defaults.
        if dataForActivePoints.isEmpty {
            return (min: rangeMin, max: rangeMax)
        }
        else {
            let range = calculateRange(for: dataForActivePoints)
            return clean(range: range)
        }
    }
    
    private func calculateRange<T: Collection>(for data: T) -> (min: Double, max: Double)
    where T.Iterator.Element == Double
    {
        var rangeMin = Double(Int.max)
        var rangeMax = Double(Int.min)
        
        for dataPoint in data {
            if dataPoint > rangeMax {
                rangeMax = dataPoint
            }
            if dataPoint < rangeMin {
                rangeMin = dataPoint
            }
        }
        return (min: rangeMin, max: rangeMax)
    }
    
    private func clean(range: (min: Double, max: Double)) -> (min: Double, max: Double){
        if range.min == range.max {
            let min = shouldRangeAlwaysStartAtZero ? 0 : range.min
            let max = range.max + 1
            
            return (min: min, max: max)
        }
        else if shouldRangeAlwaysStartAtZero {
            let min = Double.zero
            var max = range.max
            
            // If we have all negative numbers and the max happens to be 0, there will cause a division by 0. Return the default height.
            if range.max == 0 {
                max = rangeMax
            }
            
            return (min: min, max: max)
        }
        else {
            return range
        }
    }
    
    private func graphWidth(forNumberOfDataPoints numberOfPoints: Int) -> CGFloat {
        return (CGFloat(numberOfPoints - 1) * dataPointSpacing) + leftmostPointPadding + rightmostPointPadding
    }
    
    private func clamp<T: Comparable>(value: T, min: T, max: T) -> T {
        Swift.max(Swift.min(value, max), min)
    }

    private func getData(forPlot plot: Plot, andActiveInterval activeInterval: CountableRange<Int>) -> [Double] {
        getData(forPlot: plot, andNewlyActivatedPoints: activeInterval.indices)
    }

    private func getData<Points>(forPlot plot: Plot, andNewlyActivatedPoints activatedPoints: Points) -> [Double]
    where Points: Collection, Points.Element == Int
    {
        guard let dataSource = dataSource else {
            return Array(repeating: 0, count: activatedPoints.count)
        }
        return activatedPoints.map { dataSource.value(forPlot: plot, atIndex: $0) }
    }
    
    // MARK: Events
    // ############
    
    // If the active points (the points we can actually see) change, then we need to update the path.
    private func activePointsDidChange() {
        let activatedPoints = determineActivatedPoints()
        
        // The plots need to know which points became active and what their values
        // are so the plots can display them properly.
        if !isInitialSetup {
            for plot in plots {
                let newData = getData(forPlot: plot, andNewlyActivatedPoints: activatedPoints)
                plot.setPlotPointPositions(forNewlyActivatedPoints: activatedPoints, withData: newData)
            }
        }
        
        updatePaths()
        updateLabelsForCurrentInterval()
    }
    
    private func rangeDidChange() {
        // If shouldAnimateOnAdapt is enabled it will kickoff any animations that need to occur.
        if shouldAnimateOnAdapt {
            startAnimations()
        }
        else {
            // Otherwise we should simple just move the data to their positions.
            for plot in plots {
                let newData = getData(forPlot: plot, andActiveInterval: activePointsInterval)
                plot.setPlotPointPositions(forNewlyActivatedPoints: intervalForActivePoints(), withData: newData)
            }
        }
        
        referenceLineView?.set(range: range)
    }
    
    private func viewportDidChange() {
        // We need to make sure all the drawing views are the same size as the viewport.
        updateFrames()
        
        // Basically this recreates the paths with the new viewport size so things are in sync, but only
        // if the viewport has changed after the initial setup. Because the initial setup will use the latest
        // viewport anyway.
        if !isInitialSetup {
            updatePaths()
            
            // Need to update the graph points so they are in their right positions for the new viewport.
            // Animate them into position if animation is enabled, but make sure to stop any current animations first.
            #if !TARGET_INTERFACE_BUILDER
                stopAnimations()
            #endif
            startAnimations()
            
            // The labels will also need to be repositioned if the viewport has changed.
            repositionActiveLabels()
        }
    }
    
    // Returns the indices of any points that became inactive (that is, "off screen"). (No order)
    private func determineDeactivatedPoints() -> [Int] {
        let currSet = Set(activePointsInterval)
        return previousActivePointsInterval.filter { !currSet.contains($0) }
    }
    
    // Returns the indices of any points that became active (on screen). (No order)
    private func determineActivatedPoints() -> [Int] {
        let prevSet = Set(previousActivePointsInterval)
        return activePointsInterval.filter { !prevSet.contains($0) }
    }
    
    // Animations
    
    private func startAnimations(withStaggerValue stagger: Double = 0) {
        var pointsToAnimate = 0 ..< 0
        
        #if !TARGET_INTERFACE_BUILDER
            if shouldAnimateOnAdapt || (isInitialSetup && shouldAnimateOnStartup) {
                pointsToAnimate = activePointsInterval
            }
        #endif
        
        for plot in plots {
            let dataForPointsToAnimate = getData(forPlot: plot, andActiveInterval: pointsToAnimate)
            plot.startAnimations(forPoints: pointsToAnimate, withData: dataForPointsToAnimate, withStaggerValue: stagger)
        }
    }
    
    private func stopAnimations() {
        for plot in plots {
            plot.dequeueAllAnimations()
        }
    }
    
    // Labels
    // TODO in 4.1: refactor all label adding & positioning code.
    
    // Update any labels for any new points that have been activated and deactivated.
    private func updateLabels(deactivatedPoints: [Int], activatedPoints: [Int]) {
        guard let ref = referenceLines else { return }
        
        // Disable any labels for the deactivated points.
        for point in deactivatedPoints {
            labelPool.deactivateLabel(forPointIndex: point)
        }
        
        // Grab an unused label and update it to the right position for the newly activated poitns
        for point in activatedPoints {
            let label = labelPool.activateLabel(forPointIndex: point)
            label.textColor = ref.dataPointLabelColor
            label.font = ref.dataPointLabelFont
            
            if let attributedText = dataSource?.attributedLabel(atIndex: point) {
                label.attributedText = attributedText
            }
            else {
                label.text = dataSource?.label(atIndex: point)
            }
            
            label.sizeToFit()
            
            // self.range.min is the current ranges minimum that has been detected
            // self.rangeMin is the minimum that should be used as specified by the user
            let rangeMin = shouldAdaptRange ? range.min : rangeMin
            let position = calculatePosition(atIndex: point, value: rangeMin)
            
            label.frame = CGRect(origin: CGPoint(x: position.x - label.frame.width / 2,
                                                 y: position.y + ref.dataPointLabelTopMargin),
                                 size: label.frame.size)

            labelsView.subviews.lazy
                .filter { $0.frame == label.frame }
                .forEach { $0.removeFromSuperview() }

            labelsView.addSubview(label)
            accessibilityElements = labelsView.subviews + (referenceLineView?.subviews ?? [])
        }
    }
    
    private func updatePlotLabels(deactivatedPoints: [Int], activatedPoints: [Int]) {
        guard let dataSource = dataSource else { return }

        for (offset, plot) in plots.enumerated() where plot.shouldShowLabels {
            var labelPool = plotLabelPool[offset]
            defer { plotLabelPool[offset] = labelPool }

            // Disable any labels for the deactivated points.
            for point in deactivatedPoints {
                labelPool.deactivateLabel(forPointIndex: point)
            }

            // Grab an unused label and update it to the right position for the newly activated poitns
            for point in activatedPoints {
                guard let plotLabelText = dataSource.plotLabel(forPlot: plot, atIndex: point) else {
                    continue
                }
                let label = labelPool.activateLabel(forPointIndex: point)
                label.text = plotLabelText
                label.textColor = plot.labelColor
                label.font = plot.labelFont

                label.sizeToFit()

                let position = calculatePosition(atIndex: point, value: dataSource.value(forPlot: plot, atIndex: point))
                label.frame = CGRect(origin: CGPoint(x: position.x - label.frame.width / 2,
                                                     y: position.y - label.frame.height + plot.labelVerticalOffset),
                                     size: label.frame.size)

                labelsView.subviews.lazy
                    .filter { $0.frame.origin == label.frame.origin }
                    .forEach { $0.removeFromSuperview() }

                labelsView.addSubview(label)
            }
        }
    }

    private func updateLabelsForCurrentInterval() {
        // Have to ensure that the labels are added if we are supposed to be showing them.
        guard let ref = referenceLines else { return }
        let filteredPoints = filterPointsForLabels(fromPoints: activePointsInterval)
        if ref.shouldShowLabels {
            updateLabels(deactivatedPoints: filteredPoints, activatedPoints: filteredPoints)
        }
        updatePlotLabels(deactivatedPoints: filteredPoints, activatedPoints: filteredPoints)
    }
    
    private func repositionActiveLabels() {
        guard let ref = referenceLines else { return }
        
        for label in labelPool.activeLabels {
            let rangeMin = shouldAdaptRange ? range.min : rangeMin
            let position = calculatePosition(atIndex: 0, value: rangeMin)
            label.frame.origin.y = position.y + ref.dataPointLabelTopMargin
        }
    }

    private func filterPointsForLabels<C: Collection>(fromPoints points: C) -> [Int]
    where C.Element == Int
    {
        guard let ref = referenceLines , ref.dataPointLabelsSparsity == 1 else {
            return Array(points)
        }
        return points.filter { $0.isMultiple(of: ref.dataPointLabelsSparsity) }
    }
    
    // MARK: - Drawing Delegate
    // ########################
    
    internal func calculatePosition(atIndex index: Int, value: Double) -> CGPoint {
        // Set range defaults based on settings:
        
        // self.range.min/max is the current ranges min/max that has been detected
        // self.rangeMin/Max is the min/max that should be used as specified by the user
        let (rangeMin, rangeMax) = shouldAdaptRange ? range : (rangeMin, rangeMax)
        
        //                                                     y = the y co-ordinate in the view for the value in the graph
        //                                                     value = the value on the graph for which we want to know its
        //     ( ( value - max )               )                        corresponding location on the y axis in the view
        // y = ( ( ----------- ) * graphHeight ) + topMargin   t = the top margin
        //     ( (  min - max  )               )               h = the height of the graph space without margins
        //                                                     min = the range's current mininum
        //                                                     max = the range's current maximum
        
        // Calculate the position on in the view for the value specified.
        var graphHeight = viewportHeight - topMargin - bottomMargin
        
        if let ref = referenceLines,
           ref.shouldShowLabels,
           let font = ref.dataPointLabelFont
        {
            graphHeight -= (font.pointSize + ref.dataPointLabelTopMargin + ref.dataPointLabelBottomMargin)
        }
        
        let x = (CGFloat(index) * dataPointSpacing) + leftmostPointPadding
        let y = (CGFloat((value - rangeMax) / (rangeMin - rangeMax)) * graphHeight) + topMargin
        
        return CGPoint(x: x, y: y)
    }
    
    internal func intervalForActivePoints() -> CountableRange<Int> {
        return activePointsInterval
    }
    
    internal func rangeForActivePoints() -> (min: Double, max: Double) {
        return range
    }
    
    internal func paddingForPoints() -> (leftmostPointPadding: CGFloat, rightmostPointPadding: CGFloat) {
        return (leftmostPointPadding: leftmostPointPadding, rightmostPointPadding: rightmostPointPadding)
    }
    
    internal func currentViewport() -> CGRect {
        return CGRect(origin: .zero, size: CGSize(width: viewportWidth, height: viewportHeight))
    }
    
    // Update any paths with the new path based on visible data points.
    internal func updatePaths() {
        zeroYPosition = calculatePosition(atIndex: 0, value: range.min).y

        drawingView.layer.sublayers?.lazy
            .compactMap { $0 as? ScrollableGraphViewDrawingLayer }
            .forEach {
                // The bar layer needs the zero Y position to set the bottom of the bar
                $0.zeroYPosition = zeroYPosition
                // Need to make sure this is set in createLinePath
                assert($0.zeroYPosition > 0)
                $0.updatePath()
            }
    }
}

// MARK: - ScrollableGraphView Settings Enums
// ##########################################

@objc public enum ScrollableGraphViewDirection : Int {
    case leftToRight
    case rightToLeft
}

// Simple queue data structure for keeping track of which
// plots have been added.
fileprivate struct SGVQueue<T> {
    private var storage: [T]
    
    var count: Int {
        return storage.count
    }

    var isEmpty: Bool {
        return storage.isEmpty
    }
    
    init() {
        storage = [T]()
    }
    
    mutating func enqueue(element: T) {
        storage.insert(element, at: 0)
    }
    
    mutating func dequeue() -> T? {
        return storage.popLast()
    }
}

// We have to be our own data source for interface builder.
#if TARGET_INTERFACE_BUILDER
extension ScrollableGraphView : ScrollableGraphViewDataSource {
    public var numberOfDisplayItems: Int {
        return 30
    }
    
    public var linePlotData: [Double] {
        return (0 ..< numberOfDisplayItems).map { _ in .random(in: 0..<100) }
    }
    
    public func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        return linePlotData[pointIndex]
    }
    
    public func label(atIndex pointIndex: Int) -> String {
        return "\(pointIndex)"
    }
    
    public func numberOfPoints() -> Int {
        return numberOfDisplayItems
    }
}
#endif
