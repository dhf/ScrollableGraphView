import UIKit

internal class ScrollableGraphViewDrawingLayer : CAShapeLayer {
    var offset: CGFloat = 0 {
        didSet {
            offsetDidChange()
        }
    }
    
    var viewportWidth: CGFloat = 0
    var viewportHeight: CGFloat = 0
    var zeroYPosition: CGFloat = 0
    
    weak var owner: Plot?
    
    var active = true
    
    init(viewportWidth: CGFloat, viewportHeight: CGFloat, offset: CGFloat = 0) {
        super.init()
        
        self.viewportWidth = viewportWidth
        self.viewportHeight = viewportHeight
        
        self.frame = CGRect(origin: CGPoint(x: offset, y: 0),
                            size: CGSize(width: viewportWidth, height: viewportHeight))
        
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        // Get rid of any animations.
        actions = ["position": NSNull(), "bounds": NSNull()]
    }
    
    private func offsetDidChange() {
        frame.origin.x = offset
        bounds.origin.x = offset
    }
    
    func updatePath() {
        assertionFailure("updatePath needs to be implemented by the subclass")
    }
}
