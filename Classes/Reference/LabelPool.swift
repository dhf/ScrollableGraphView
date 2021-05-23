
import UIKit

internal final class LabelPool {
    private(set) var labels    = [UILabel]()
    private(set) var relations = [Int: Int]()
    private(set) var unused    = [Int]()
    
    func deactivateLabel(forPointIndex pointIndex: Int) {
        if let unusedLabelIndex = relations[pointIndex] {
            unused.append(unusedLabelIndex)
        }
        relations[pointIndex] = nil
    }
    
    @discardableResult
    func activateLabel(forPointIndex pointIndex: Int) -> UILabel {
        guard let unusedLabelIndex = unused.popLast() else {
            let newLabel = UILabel()
            newLabel.numberOfLines = 1
            newLabel.textAlignment = .center
            
            let newLabelIndex = labels.count
            labels.insert(newLabel, at: newLabelIndex)
            relations[pointIndex] = newLabelIndex
            
            return newLabel
        }
        
        let reuseLabel = labels[unusedLabelIndex]
        relations[pointIndex] = unusedLabelIndex
        
        return reuseLabel
    }
    
    var activeLabels: [UILabel] {
        var currentlyActive = [UILabel]()
        let numberOfLabels = labels.count
        
        for i in 0 ..< numberOfLabels {
            if !unused.contains(i) {
                currentlyActive.append(labels[i])
            }
        }
        return currentlyActive
    }
}
