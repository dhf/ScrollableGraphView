import UIKit

internal class ReferenceLineDrawingView : UIView {
    var settings = ReferenceLines()
    
    // PRIVATE PROPERTIES
    // ##################
    
    private var labelMargin: CGFloat = 4
    private var leftLabelInset: CGFloat = 10
    private var rightLabelInset: CGFloat = 10
    
    // Store information about the ScrollableGraphView
    private var currentRange: (min: Double, max: Double) = (0,100)
    private var topMargin: CGFloat = 10
    private var bottomMargin: CGFloat = 10
    
    private var lineWidth: CGFloat { return bounds.width }
    
    private var units: String {
        if let units = settings.referenceLineUnits {
            return " \(units)"
        } else {
            return ""
        }
    }
    
    // Layers
    private var labels = [UILabel]()
    private let referenceLineLayer = CAShapeLayer()
    private let referenceLinePath = UIBezierPath()
    
    init(frame: CGRect,
         topMargin: CGFloat,
         bottomMargin: CGFloat,
         referenceLineColor: UIColor,
         referenceLineThickness: CGFloat,
         referenceLineSettings: ReferenceLines) {
        super.init(frame: frame)
        
        self.topMargin = topMargin
        self.bottomMargin = bottomMargin
        
        // The reference line layer draws the reference lines and we handle the labels elsewhere.
        self.referenceLineLayer.frame = self.frame
        self.referenceLineLayer.strokeColor = referenceLineColor.cgColor
        self.referenceLineLayer.lineWidth = referenceLineThickness
        
        self.settings = referenceLineSettings
        
        self.layer.addSublayer(referenceLineLayer)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLabel(at position: CGPoint, withText text: String) -> UILabel {
        return UILabel(frame: CGRect(origin: position, size: .zero))
    }
    
    private func createReferenceLinesPath() -> UIBezierPath {
        referenceLinePath.removeAllPoints()
        for label in labels {
            label.removeFromSuperview()
        }
        labels.removeAll()
        
        if settings.includeMinMax {
            let maxLineStart = CGPoint(x: 0, y: topMargin)
            let maxLineEnd = CGPoint(x: lineWidth, y: topMargin)
            
            let minLineStart = CGPoint(x: 0, y: bounds.height - bottomMargin)
            let minLineEnd = CGPoint(x: lineWidth, y: bounds.height - bottomMargin)
            
            let numberFormatter = referenceNumberFormatter()
            
            let maxString = numberFormatter.string(from: currentRange.max as NSNumber)! + units
            let minString = numberFormatter.string(from: currentRange.min as NSNumber)! + units
            
            addLine(withTag: maxString, from: maxLineStart, to: maxLineEnd, in: referenceLinePath)
            addLine(withTag: minString, from: minLineStart, to: minLineEnd, in: referenceLinePath)
        }

        let initialRect = CGRect(origin: CGPoint(x: bounds.origin.x, y: bounds.origin.y + topMargin),
                                 size: CGSize(width: bounds.width, height: bounds.height - (topMargin + bottomMargin)))
        
        switch settings.positionType {
        case .relative:
            createReferenceLines(in: initialRect, atRelativePositions: settings.relativePositions, forPath: referenceLinePath)
        case .absolute:
            createReferenceLines(in: initialRect, atAbsolutePositions: settings.absolutePositions, forPath: referenceLinePath)
        }
        
        return referenceLinePath
    }
    
    private func referenceNumberFormatter() -> NumberFormatter {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = settings.referenceLineNumberStyle
        numberFormatter.minimumFractionDigits = settings.referenceLineNumberOfDecimalPlaces
        numberFormatter.maximumFractionDigits = settings.referenceLineNumberOfDecimalPlaces
        
        return numberFormatter
    }
    
    private func createReferenceLines(in rect: CGRect, atRelativePositions relativePositions: [Double], forPath path: UIBezierPath) {
        let height = rect.size.height
        var relativePositions = relativePositions
        
        // If we are including the min and max already need to make sure we don't redraw them.
        if settings.includeMinMax {
            relativePositions = relativePositions.filter { $0 != 0 && $0 != 1 }
        }
        
        for relativePosition in relativePositions {
            let yPosition = height * CGFloat(1 - relativePosition)
            
            let lineStart = CGPoint(x: 0, y: rect.origin.y + yPosition)
            let lineEnd = CGPoint(x: lineStart.x + lineWidth, y: lineStart.y)
            
            createReferenceLineFrom(from: lineStart, to: lineEnd, in: path)
        }
    }
    
    private func createReferenceLines(in rect: CGRect, atAbsolutePositions absolutePositions: [Double], forPath path: UIBezierPath) {
        for absolutePosition in absolutePositions {
            let yPosition = calculateYPositionForYAxisValue(value: absolutePosition)
            
            // don't need to add rect.origin.y to yPosition like we do for relativePositions,
            // as we calculate the position for the y axis value in the previous line,
            // this already takes into account margins, etc.
            let lineStart = CGPoint(x: 0, y: yPosition)
            let lineEnd = CGPoint(x: lineStart.x + lineWidth, y: lineStart.y)
            
            createReferenceLineFrom(from: lineStart, to: lineEnd, in: path)
        }
    }
    
    private func createReferenceLineFrom(from lineStart: CGPoint, to lineEnd: CGPoint, in path: UIBezierPath) {
        if settings.shouldAddLabelsToIntermediateReferenceLines {
            let value = calculateYAxisValue(for: lineStart)
            let numberFormatter = referenceNumberFormatter()
            var valueString = numberFormatter.string(from: value as NSNumber)!
            
            if settings.shouldAddUnitsToIntermediateReferenceLineLabels {
                valueString += " \(units)"
            }
            
            addLine(withTag: valueString, from: lineStart, to: lineEnd, in: path)
        } else {
            addLine(from: lineStart, to: lineEnd, in: path)
        }
    }
    
    private func addLine(withTag tag: String, from: CGPoint, to: CGPoint, in path: UIBezierPath) {
        let boundingSize = self.boundingSize(forText: tag)
        let leftLabel = createLabel(withText: tag)
        let rightLabel = createLabel(withText: tag)
        
        // Left label gap.
        leftLabel.frame = CGRect(
            origin: CGPoint(x: from.x + leftLabelInset, y: from.y - (boundingSize.height / 2)),
            size: boundingSize
        )
        
        let leftLabelStart = CGPoint(x: leftLabel.frame.origin.x - labelMargin, y: to.y)
        let leftLabelEnd = CGPoint(x: (leftLabel.frame.origin.x + leftLabel.frame.size.width) + labelMargin, y: to.y)
        
        // Right label gap.
        rightLabel.frame = CGRect(
            origin: CGPoint(x: (from.x + frame.width) - rightLabelInset - boundingSize.width, y: from.y - (boundingSize.height / 2)),
            size: boundingSize)
        
        let rightLabelStart = CGPoint(x: rightLabel.frame.origin.x - labelMargin, y: to.y)
        let rightLabelEnd = CGPoint(x: (rightLabel.frame.origin.x + rightLabel.frame.size.width) + labelMargin, y: to.y)
        
        // Add the lines and tags depending on the settings for where we want them.
        var gaps = [(start: CGFloat, end: CGFloat)]()
        switch settings.referenceLinePosition {
        case .left:
            gaps.append((start: leftLabelStart.x, end: leftLabelEnd.x))
            addSubview(leftLabel)
            labels.append(leftLabel)
            
        case .right:
            gaps.append((start: rightLabelStart.x, end: rightLabelEnd.x))
            addSubview(rightLabel)
            labels.append(rightLabel)
            
        case .both:
            gaps.append((start: leftLabelStart.x, end: leftLabelEnd.x))
            gaps.append((start: rightLabelStart.x, end: rightLabelEnd.x))
            addSubview(leftLabel)
            addSubview(rightLabel)
            labels.append(leftLabel)
            labels.append(rightLabel)
        }
        
        addLine(from: from, to: to, withGaps: gaps, in: path)
    }
    
    private func addLine(from: CGPoint, to: CGPoint, withGaps gaps: [(start: CGFloat, end: CGFloat)], in path: UIBezierPath) {
        // If there are no gaps, just add a single line.
        if gaps.isEmpty {
            addLine(from: from, to: to, in: path)
        }
            // If there is only 1 gap, it's just two lines.
        else if gaps.count == 1 {
            let gapLeft = CGPoint(x: gaps[0].start, y: from.y)
            let gapRight = CGPoint(x: gaps[0].end, y: from.y)
            
            addLine(from: from, to: gapLeft, in: path)
            addLine(from: gapRight, to: to, in: path)
        }
            // If there are many gaps, we have a series of intermediate lines.
        else {
            let firstGap = gaps[0]
            let lastGap = gaps[gaps.index(before: gaps.endIndex)]
            
            let firstGapLeft = CGPoint(x: firstGap.start, y: from.y)
            let lastGapRight = CGPoint(x: lastGap.end, y: to.y)
            
            // Add the first line to the start of the first gap
            addLine(from: from, to: firstGapLeft, in: path)
            
            // Add lines between all intermediate gaps
            for i in gaps.indices.dropLast() {
                
                let startGapEnd = gaps[i].end
                let endGapStart = gaps[i + 1].start
                
                let lineStart = CGPoint(x: startGapEnd, y: from.y)
                let lineEnd = CGPoint(x: endGapStart, y: from.y)
                
                addLine(from: lineStart, to: lineEnd, in: path)
            }
            
            // Add the final line to the end
            addLine(from: lastGapRight, to: to, in: path)
        }
    }
    
    private func addLine(from: CGPoint, to: CGPoint, in path: UIBezierPath) {
        path.move(to: from)
        path.addLine(to: to)
    }
    
    private func boundingSize(forText text: String) -> CGSize {
        return text.size(withAttributes: [.font: settings.referenceLineLabelFont])
    }
    
    private func calculateYAxisValue(for point: CGPoint) -> Double {
        let graphHeight = frame.size.height - (topMargin + bottomMargin)
        
        //                                          value = the corresponding value on the graph for any y co-ordinate in the view
        //           y - t                          y = the y co-ordinate in the view for which we want to know the corresponding value on the graph
        // value = --------- * (min - max) + max    t = the top margin
        //             h                            h = the height of the graph space without margins
        //                                          min = the range's current mininum
        //                                          max = the range's current maximum
        
        var value = (((point.y - topMargin) / (graphHeight)) * CGFloat((currentRange.min - currentRange.max))) + CGFloat(currentRange.max)
        
        // Clean "negative zero"
        if value.isZero {
            value = 0
        }
        
        return Double(value)
    }
    
    private func calculateYPositionForYAxisValue(value: Double) -> CGFloat {
        // Just an algebraic re-arrangement of calculateYAxisValue
        let graphHeight = frame.size.height - (topMargin + bottomMargin)
        var y = ((CGFloat(value - currentRange.max) / CGFloat(currentRange.min - currentRange.max)) * graphHeight) + topMargin

        // Clean "negative zero"
        if y.isZero {
            y = 0
        }
        
        return y
    }
    
    private func createLabel(withText text: String) -> UILabel {
        let label = UILabel()
        
        label.text = text
        label.textColor = settings.referenceLineLabelColor
        label.font = settings.referenceLineLabelFont
        
        return label
    }
    
    // Public functions to update the reference lines with any changes to the range and viewport (phone rotation, etc).
    // When the range changes, need to update the max for the new range, then update all the labels that are showing for the axis and redraw the reference lines.
    func set(range: (min: Double, max: Double)) {
        currentRange = range
        referenceLineLayer.path = createReferenceLinesPath().cgPath
    }
    
    func set(viewportWidth: CGFloat, viewportHeight: CGFloat) {
        frame.size.width = viewportWidth
        frame.size.height = viewportHeight
        referenceLineLayer.path = createReferenceLinesPath().cgPath
    }
}
