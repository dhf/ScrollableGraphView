//
//  Examples.swift
//  GraphView
//
//  Created by Kelly Roach on 8/18/18.
//

import UIKit

class Examples : ScrollableGraphViewDataSource {
    // MARK: Data Properties
    public var showPlotLabels: Bool = false
    
    private var numberOfDataItems = 29

    // Data for graphs with a single plot
    private lazy var simpleLinePlotData: [Double] = generateRandomData(numberOfDataItems, max: 100, shouldIncludeOutliers: false)
    private lazy var darkLinePlotData: [Double] = generateRandomData(numberOfDataItems, max: 50, shouldIncludeOutliers: true)
    private lazy var dotPlotData: [Double] =  generateRandomData(numberOfDataItems, variance: 4, from: 25)
    private lazy var barPlotData: [Double] =  generateRandomData(numberOfDataItems, max: 100, shouldIncludeOutliers: false)
    private lazy var pinkLinePlotData: [Double] =  generateRandomData(numberOfDataItems, max: 100, shouldIncludeOutliers: false)
    
    // Data for graphs with multiple plots
    private lazy var blueLinePlotData: [Double] = generateRandomData(numberOfDataItems, max: 50)
    private lazy var orangeLinePlotData: [Double] =  generateRandomData(numberOfDataItems, max: 40, shouldIncludeOutliers: false)
    
    // Labels for the x-axis
    
    private lazy var xAxisLabels: [String] =  generateSequentialLabels(numberOfDataItems, text: "FEB")
    
    // MARK: ScrollableGraphViewDataSource protocol
    // #########################################################
    
    // You would usually only have a couple of cases here, one for each
    // plot you want to display on the graph. However as this is showing
    // off many graphs with different plots, we are using one big switch
    // statement.
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        return dataValue(forPlot: plot, atIndex: pointIndex)
    }
    
    func label(atIndex pointIndex: Int) -> String {
        // Ensure that you have a label to return for the index
        return xAxisLabels[pointIndex]
    }

    func plotLabel(forPlot plot: Plot, atIndex pointIndex: Int) -> String? {
        return "\(dataValue(forPlot: plot, atIndex: pointIndex))"
    }

    func numberOfPoints() -> Int {
        return numberOfDataItems
    }

    func dataValue(forPlot plot: Plot, atIndex pointIndex: Int) -> Double {
        switch(plot.identifier) {

        // Data for the graphs with a single plot
        case "simple":
            return simpleLinePlotData[pointIndex]
        case "darkLine":
            return darkLinePlotData[pointIndex]
        case "darkLineDot":
            return darkLinePlotData[pointIndex]
        case "bar":
            return barPlotData[pointIndex]
        case "dot":
            return dotPlotData[pointIndex]
        case "pinkLine":
            return pinkLinePlotData[pointIndex]

        // Data for MULTI graphs
        case "multiBlue":
            return blueLinePlotData[pointIndex]
        case "multiBlueDot":
            return blueLinePlotData[pointIndex]
        case "multiOrange":
            return orangeLinePlotData[pointIndex]
        case "multiOrangeSquare":
            return orangeLinePlotData[pointIndex]

        default:
            return 0
        }
    }
    
    // MARK: Example Graphs
    // ##################################
    
    // The simplest kind of graph
    // A single line plot, with no range adaption when scrolling
    // No animations
    // min: 0
    // max: 100
    func createSimpleGraph(_ frame: CGRect) -> ScrollableGraphView {
        
        // Compose the graph view by creating a graph, then adding any plots
        // and reference lines before adding the graph to the view hierarchy.
        let graphView = ScrollableGraphView(frame: frame, dataSource: self)
        
        let linePlot = LinePlot(identifier: "simple") // Identifier should be unique for each plot.
        linePlot.labelVerticalOffset = -5

        let referenceLines = ReferenceLines()
        
        graphView.addPlot(plot: linePlot)
        graphView.addReferenceLines(referenceLines: referenceLines)
        
        return graphView
    }
    
    // Multi plot v1
    // min: 0
    // max: determined from active points
    // The max reference line will be the max of all visible points
    // Reference lines are placed relatively, at 0%, 20%, 40%, 60%, 80% and 100% of the max
    func createMultiPlotGraphOne(_ frame: CGRect) -> ScrollableGraphView {
        let graphView = ScrollableGraphView(frame: frame, dataSource: self)
        
        // Setup the first plot.
        let blueLinePlot = LinePlot(identifier: "multiBlue")
        
        blueLinePlot.lineColor = .colorFromHex(hexString: "#16aafc")
        blueLinePlot.adaptAnimationType = .elastic
        blueLinePlot.shouldShowLabels = true
        blueLinePlot.labelVerticalOffset = -10
        blueLinePlot.labelColor = .white
        
        // dots on the line
        let blueDotPlot = DotPlot(identifier: "multiBlueDot")
        blueDotPlot.dataPointType = .circle
        blueDotPlot.dataPointSize = 5
        blueDotPlot.dataPointFillColor = .colorFromHex(hexString: "#16aafc")

        blueDotPlot.adaptAnimationType = .elastic
        
        // Setup the second plot.
        let orangeLinePlot = LinePlot(identifier: "multiOrange")
        
        orangeLinePlot.lineColor = .colorFromHex(hexString: "#ff7d78")
        orangeLinePlot.adaptAnimationType = .elastic
        orangeLinePlot.labelVerticalOffset = -10
        orangeLinePlot.shouldShowLabels = true
        orangeLinePlot.labelColor = .white

        // squares on the line
        let orangeSquarePlot = DotPlot(identifier: "multiOrangeSquare")
        orangeSquarePlot.dataPointType = .square
        orangeSquarePlot.dataPointSize = 5
        orangeSquarePlot.dataPointFillColor = .colorFromHex(hexString: "#ff7d78")
        
        orangeSquarePlot.adaptAnimationType = .elastic
        
        // Setup the reference lines.
        let referenceLines = ReferenceLines()
        
        referenceLines.referenceLineLabelFont = .boldSystemFont(ofSize: 8)
        referenceLines.referenceLineColor = .white.withAlphaComponent(0.2)
        referenceLines.referenceLineLabelColor = .white
        referenceLines.relativePositions = [0, 0.2, 0.4, 0.6, 0.8, 1]
        
        referenceLines.dataPointLabelColor = .white.withAlphaComponent(1)
        
        // Setup the graph
        graphView.backgroundFillColor = .colorFromHex(hexString: "#333333")
        
        graphView.dataPointSpacing = 80
        
        graphView.shouldAnimateOnStartup = true
        graphView.shouldAdaptRange = true
        graphView.shouldRangeAlwaysStartAtZero = true
        
        // Add everything to the graph.
        graphView.addReferenceLines(referenceLines: referenceLines)
        graphView.addPlot(plot: blueLinePlot)
        graphView.addPlot(plot: blueDotPlot)
        graphView.addPlot(plot: orangeLinePlot)
        graphView.addPlot(plot: orangeSquarePlot)
        
        return graphView
    }
    
    // Multi plot v2
    // min: 0
    // max: determined from active points
    // The max reference line will be the max of all visible points
    func createMultiPlotGraphTwo(_ frame: CGRect) -> ScrollableGraphView {
        let graphView = ScrollableGraphView(frame: frame, dataSource: self)
        
        // Setup the line plot.
        let blueLinePlot = LinePlot(identifier: "multiBlue")
        
        blueLinePlot.lineWidth = 1
        blueLinePlot.lineColor = .colorFromHex(hexString: "#16aafc")
        blueLinePlot.lineStyle = .smooth
        blueLinePlot.labelVerticalOffset = -10
        blueLinePlot.labelColor = .white

        blueLinePlot.shouldFill = true
        blueLinePlot.fillType = .solid
        blueLinePlot.fillColor = .colorFromHex(hexString: "#16aafc").withAlphaComponent(0.5)
        
        blueLinePlot.adaptAnimationType = .elastic
        
        // Setup the second line plot.
        let orangeLinePlot = LinePlot(identifier: "multiOrange")
        
        orangeLinePlot.lineWidth = 1
        orangeLinePlot.lineColor = .colorFromHex(hexString: "#ff7d78")
        orangeLinePlot.lineStyle = .smooth
        orangeLinePlot.labelVerticalOffset = -10
        orangeLinePlot.labelColor = .white

        orangeLinePlot.shouldFill = true
        orangeLinePlot.fillType = .solid
        orangeLinePlot.fillColor = .colorFromHex(hexString: "#ff7d78").withAlphaComponent(0.5)
        
        orangeLinePlot.adaptAnimationType = .elastic
        
        // Setup the reference lines.
        let referenceLines = ReferenceLines()
        
        referenceLines.referenceLineLabelFont = .boldSystemFont(ofSize: 8)
        referenceLines.referenceLineColor = .white.withAlphaComponent(0.2)
        referenceLines.referenceLineLabelColor = .white
        
        referenceLines.dataPointLabelColor = .white.withAlphaComponent(1)
        
        // Setup the graph
        graphView.backgroundFillColor = .colorFromHex(hexString: "#333333")
        
        graphView.dataPointSpacing = 80
        graphView.shouldAnimateOnStartup = true
        graphView.shouldAdaptRange = true
        
        graphView.shouldRangeAlwaysStartAtZero = true
        
        // Add everything to the graph.
        graphView.addReferenceLines(referenceLines: referenceLines)
        graphView.addPlot(plot: blueLinePlot)
        graphView.addPlot(plot: orangeLinePlot)
        
        return graphView
    }
    
    // Reference lines are positioned absolutely. will appear at specified values on y axis
    func createDarkGraph(_ frame: CGRect) -> ScrollableGraphView {
        let graphView = ScrollableGraphView(frame: frame, dataSource: self)
        
        // Setup the line plot.
        let linePlot = LinePlot(identifier: "darkLine")
        
        linePlot.lineWidth = 1
        linePlot.lineColor = .colorFromHex(hexString: "#777777")
        linePlot.lineStyle = .smooth
        linePlot.labelVerticalOffset = -10
        linePlot.labelColor = .white

        
        linePlot.shouldFill = true
        linePlot.fillType = .gradient
        linePlot.fillGradientType = .linear
        linePlot.fillGradientStartColor = .colorFromHex(hexString: "#555555")
        linePlot.fillGradientEndColor = .colorFromHex(hexString: "#444444")
        
        linePlot.adaptAnimationType = .elastic
        
        let dotPlot = DotPlot(identifier: "darkLineDot") // Add dots as well.
        dotPlot.dataPointSize = 2
        dotPlot.dataPointFillColor = .white
        
        dotPlot.adaptAnimationType = .elastic
        
        // Setup the reference lines.
        let referenceLines = ReferenceLines()
        
        referenceLines.referenceLineLabelFont = .boldSystemFont(ofSize: 8)
        referenceLines.referenceLineColor = .white.withAlphaComponent(0.2)
        referenceLines.referenceLineLabelColor = .white
        
        referenceLines.positionType = .absolute
        // Reference lines will be shown at these values on the y-axis.
        referenceLines.absolutePositions = [10, 20, 25, 30]
        referenceLines.includeMinMax = false
        
        referenceLines.dataPointLabelColor = .white.withAlphaComponent(0.5)
        
        // Setup the graph
        graphView.backgroundFillColor = .colorFromHex(hexString: "#333333")
        graphView.dataPointSpacing = 80
        
        graphView.shouldAnimateOnStartup = true
        graphView.shouldAdaptRange = true
        graphView.shouldRangeAlwaysStartAtZero = true
        
        graphView.rangeMax = 50
        
        // Add everything to the graph.
        graphView.addReferenceLines(referenceLines: referenceLines)
        graphView.addPlot(plot: linePlot)
        graphView.addPlot(plot: dotPlot)
        
        return graphView
    }
    
    // min: 0
    // max: 100
    // Will not adapt min and max reference lines to range of visible points
    func createBarGraph(_ frame: CGRect) -> ScrollableGraphView {
        
        let graphView = ScrollableGraphView(frame: frame, dataSource: self)
        
        // Setup the plot
        let barPlot = BarPlot(identifier: "bar")
        
        barPlot.barWidth = 25
        barPlot.barLineWidth = 1
        barPlot.barLineColor = .colorFromHex(hexString: "#777777")
        barPlot.barColor = .colorFromHex(hexString: "#555555")
        barPlot.labelVerticalOffset = -10
        barPlot.labelColor = .white

        barPlot.adaptAnimationType = .elastic
        barPlot.animationDuration = 1.5
        
        // Setup the reference lines
        let referenceLines = ReferenceLines()
        
        referenceLines.referenceLineLabelFont = .boldSystemFont(ofSize: 8)
        referenceLines.referenceLineColor = .white.withAlphaComponent(0.2)
        referenceLines.referenceLineLabelColor = .white
        
        referenceLines.dataPointLabelColor = .white.withAlphaComponent(0.5)
        
        // Setup the graph
        graphView.backgroundFillColor = .colorFromHex(hexString: "#333333")
        
        graphView.shouldAnimateOnStartup = true
        
        graphView.rangeMax = 100
        graphView.rangeMin = 0
        
        // Add everything
        graphView.addPlot(plot: barPlot)
        graphView.addReferenceLines(referenceLines: referenceLines)
        return graphView
    }
    
    // min: 0
    // max 50
    // Will not adapt min and max reference lines to range of visible points
    // no animations
    func createDotGraph(_ frame: CGRect) -> ScrollableGraphView {
        
        let graphView = ScrollableGraphView(frame: frame, dataSource: self)
        
        // Setup the plot
        let plot = DotPlot(identifier: "dot")
        
        plot.dataPointSize = 5
        plot.dataPointFillColor = .white
        plot.labelVerticalOffset = -10
        plot.labelColor = .white

        
        // Setup the reference lines
        let referenceLines = ReferenceLines()
        referenceLines.referenceLineLabelFont = .boldSystemFont(ofSize: 10)
        referenceLines.referenceLineColor = .white.withAlphaComponent(0.5)
        referenceLines.referenceLineLabelColor = .white
        referenceLines.referenceLinePosition = .both
        
        referenceLines.shouldShowLabels = false
        
        // Setup the graph
        graphView.backgroundFillColor = .colorFromHex(hexString: "#00BFFF")
        graphView.shouldAdaptRange = false
        graphView.shouldAnimateOnAdapt = false
        graphView.shouldAnimateOnStartup = false
        
        graphView.dataPointSpacing = 25
        graphView.rangeMax = 50
        graphView.rangeMin = 0
        
        // Add everything
        graphView.addPlot(plot: plot)
        graphView.addReferenceLines(referenceLines: referenceLines)
        return graphView
    }
    
    // min: min of visible points
    // max: max of visible points
    // Will adapt min and max reference lines to range of visible points
    func createPinkGraph(_ frame: CGRect) -> ScrollableGraphView {
        
        let graphView = ScrollableGraphView(frame: frame, dataSource: self)
        
        // Setup the plot
        let linePlot = LinePlot(identifier: "pinkLine")
        
        linePlot.lineColor = .clear
        linePlot.shouldFill = true
        linePlot.fillColor = .colorFromHex(hexString: "#FF0080")
        linePlot.labelVerticalOffset = -10
        linePlot.labelColor = .white

        // Setup the reference lines
        let referenceLines = ReferenceLines()
        
        referenceLines.referenceLineThickness = 1
        referenceLines.referenceLineLabelFont = .boldSystemFont(ofSize: 10)
        referenceLines.referenceLineColor = .white.withAlphaComponent(0.5)
        referenceLines.referenceLineLabelColor = .white
        referenceLines.referenceLinePosition = .both
        
        referenceLines.dataPointLabelFont = .boldSystemFont(ofSize: 10)
        referenceLines.dataPointLabelColor = .white
        referenceLines.dataPointLabelsSparsity = 3
        
        // Setup the graph
        graphView.backgroundFillColor = .colorFromHex(hexString: "#222222")
        
        graphView.dataPointSpacing = 60
        graphView.shouldAdaptRange = true
        
        // Add everything
        graphView.addPlot(plot: linePlot)
        graphView.addReferenceLines(referenceLines: referenceLines)
        return graphView
    }
    
    //
    func createBlueOrangeGraph(_ frame: CGRect) -> ScrollableGraphView {
        let graphView = ScrollableGraphView(frame: frame, dataSource: self)
        // Setup the first line plot.
        let blueLinePlot = LinePlot(identifier: "multiBlue")
        
        blueLinePlot.lineWidth = 5
        blueLinePlot.lineColor = .colorFromHex(hexString: "#16aafc")
        blueLinePlot.lineStyle = .smooth
        
        blueLinePlot.shouldFill = false
        blueLinePlot.fillType = .solid
        blueLinePlot.fillColor = .colorFromHex(hexString: "#16aafc").withAlphaComponent(0.5)
        blueLinePlot.labelVerticalOffset = -10
        
        blueLinePlot.adaptAnimationType = .elastic
        
        // Setup the second line plot.
        let orangeLinePlot = LinePlot(identifier: "multiOrange")
        
        orangeLinePlot.lineWidth = 5
        orangeLinePlot.lineColor = .colorFromHex(hexString: "#ff7d78")
        orangeLinePlot.lineStyle = .smooth
        orangeLinePlot.labelVerticalOffset = -10

        orangeLinePlot.shouldFill = false
        orangeLinePlot.fillType = .solid
        orangeLinePlot.fillColor = .colorFromHex(hexString: "#ff7d78").withAlphaComponent(0.5)
        
        orangeLinePlot.adaptAnimationType = .elastic
        
        // Customise the reference lines.
        let referenceLines = ReferenceLines()
        
        referenceLines.referenceLineLabelFont = .boldSystemFont(ofSize: 8)
        referenceLines.referenceLineColor = .black.withAlphaComponent(0.2)
        referenceLines.referenceLineLabelColor = .black
        
        referenceLines.dataPointLabelColor = .black.withAlphaComponent(1)
        
        // All other graph customisation is done in Interface Builder,
        // e.g, the background colour would be set in interface builder rather than in code.
        // graphView.backgroundFillColor = UIColor.colorFromHex(hexString: "#333333")
        
        // Add everything to the graph.
        graphView.addReferenceLines(referenceLines: referenceLines)
        graphView.addPlot(plot: blueLinePlot)
        graphView.addPlot(plot: orangeLinePlot)
        return graphView
    }
    
    // MARK: Data Generation
    
    func reload() {
        // Currently changing the number of data items is not supported.
        // It is only possible to change the the actual values of the data before reloading.
        // numberOfDataItems = 30
        
        // data for graphs with a single plot
        simpleLinePlotData = generateRandomData(numberOfDataItems, max: 100, shouldIncludeOutliers: false)
        darkLinePlotData = generateRandomData(numberOfDataItems, max: 50, shouldIncludeOutliers: true)
        dotPlotData = generateRandomData(numberOfDataItems, variance: 4, from: 25)
        barPlotData = generateRandomData(numberOfDataItems, max: 100, shouldIncludeOutliers: false)
        pinkLinePlotData = generateRandomData(numberOfDataItems, max: 100, shouldIncludeOutliers: false)
        
        // data for graphs with multiple plots
        blueLinePlotData = generateRandomData(numberOfDataItems, max: 50)
        orangeLinePlotData = generateRandomData(numberOfDataItems, max: 40, shouldIncludeOutliers: false)
        
        // update labels
        xAxisLabels = generateSequentialLabels(numberOfDataItems, text: "MAR")
    }
    
    private func generateRandomData(_ numberOfItems: Int, max: Double, shouldIncludeOutliers: Bool = true) -> [Double] {
        var data = [Double]()
        for _ in 0 ..< numberOfItems {
            var randomNumber = Double(arc4random()).truncatingRemainder(dividingBy: max)
            
            if(shouldIncludeOutliers) {
                if(arc4random() % 100 < 10) {
                    randomNumber *= 3
                }
            }
            
            data.append(randomNumber)
        }
        return data
    }
    
    private func generateRandomData(_ numberOfItems: Int, variance: Double, from: Double) -> [Double] {
        
        var data = [Double]()
        for _ in 0 ..< numberOfItems {
            
            let randomVariance = Double(arc4random()).truncatingRemainder(dividingBy: variance)
            var randomNumber = from
            
            if(arc4random() % 100 < 50) {
                randomNumber += randomVariance
            }
            else {
                randomNumber -= randomVariance
            }
            
            data.append(randomNumber)
        }
        return data
    }
    
    private func generateSequentialLabels(_ numberOfItems: Int, text: String) -> [String] {
        var labels = [String]()
        for i in 0 ..< numberOfItems {
            labels.append("\(text) \(i+1)")
        }
        return labels
    }
}
