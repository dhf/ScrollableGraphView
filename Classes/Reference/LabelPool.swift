import UIKit

struct LabelPool {
    private(set) var labels    = [UILabel]()
    private(set) var relations = [Int: Int]()
    private(set) var unused    = Set<Int>()

    var activeLabels: [UILabel] {
        zip(labels.indices, labels)
            .lazy
            .filter { !unused.contains($0.0) }
            .map { $0.1 }
    }
    
    mutating func deactivateLabel(forPointIndex pointIndex: Int) {
        guard let unusedLabelIndex = relations.removeValue(forKey: pointIndex)
        else { return }
        let inserted = unused.insert(unusedLabelIndex).inserted
        assert(inserted)
    }
    
    @discardableResult
    mutating func activateLabel(forPointIndex pointIndex: Int) -> UILabel {
        guard let unusedLabelIndex = unused.popFirst() else {
            let newLabel = UILabel()
            newLabel.numberOfLines = 1
            newLabel.textAlignment = .center
            
            let newLabelIndex = labels.endIndex
            labels.insert(newLabel, at: newLabelIndex)
            relations[pointIndex] = newLabelIndex
            
            return newLabel
        }
        
        let reuseLabel = labels[unusedLabelIndex]
        relations[pointIndex] = unusedLabelIndex
        
        return reuseLabel
    }
}
