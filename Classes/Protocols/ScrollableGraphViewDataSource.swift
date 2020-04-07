
import UIKit

public protocol ScrollableGraphViewDataSource: AnyObject {
    func value(forPlot plot: Plot, atIndex pointIndex: Int) -> Double
    func label(atIndex pointIndex: Int) -> String
    func attributedLabel(atIndex pointIndex: Int) -> NSAttributedString?
    func numberOfPoints() -> Int // This now forces the same number of points in each plot.
}

public extension ScrollableGraphViewDataSource {
    func attributedLabel(atIndex pointIndex: Int) -> NSAttributedString? {
        return nil
    }
}
