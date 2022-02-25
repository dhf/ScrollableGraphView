import UIKit

internal class GradientDrawingLayer : ScrollableGraphViewDrawingLayer {
    
    private var startColor: UIColor
    private var endColor: UIColor
    private var gradientType: ScrollableGraphViewGradientType
    
    // Gradient fills are only used with lineplots and we need 
    // to know what the line looks like.
    private var lineDrawingLayer: LineDrawingLayer
    
    lazy private var gradientMask: CAShapeLayer = {
        let mask = CAShapeLayer()
        
        mask.frame = CGRect(origin: .zero,
                            size: CGSize(width: viewportWidth, height: viewportHeight))
        mask.fillRule = .evenOdd
        mask.lineJoin = lineJoin
        
        return mask
    }()
    
    init(frame: CGRect,
         startColor: UIColor,
         endColor: UIColor,
         gradientType: ScrollableGraphViewGradientType,
         lineJoin: CAShapeLayerLineJoin = .round,
         lineDrawingLayer: LineDrawingLayer) {
        self.startColor = startColor
        self.endColor = endColor
        self.gradientType = gradientType
        //self.lineJoin = lineJoin
        
        self.lineDrawingLayer = lineDrawingLayer
        
        super.init(viewportWidth: frame.size.width, viewportHeight: frame.size.height)
        
        addMaskLayer()
        setNeedsDisplay()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addMaskLayer() {
        mask = gradientMask
    }
    
    override func updatePath() {
        gradientMask.path = lineDrawingLayer.createLinePath().cgPath
    }
    
    override func draw(in ctx: CGContext) {
        let colors = [startColor.cgColor, endColor.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0, 1]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations)
        else { return }
        
        let displacement = ((viewportWidth / viewportHeight) / 2.5) * bounds.height
        let topCentre = CGPoint(x: offset + bounds.width / 2, y: -displacement)
        let bottomCentre = CGPoint(x: offset + bounds.width / 2, y: bounds.height)
        let startRadius: CGFloat = 0
        let endRadius = bounds.width
        
        switch(gradientType) {
        case .linear:
            ctx.drawLinearGradient(gradient, start: topCentre, end: bottomCentre, options: .drawsAfterEndLocation)
        case .radial:
            ctx.drawRadialGradient(gradient, startCenter: topCentre, startRadius: startRadius, endCenter: topCentre, endRadius: endRadius, options: .drawsAfterEndLocation)
        }
    }
}
