//
//  Simple example usage of ScrollableGraphView.swift
//  #################################################
//

import UIKit

class ViewController: UIViewController {
    // MARK: Properties
    
    var examples: Examples!
    var graphView: ScrollableGraphView!
    var currentGraphType = GraphType.multiOne
    var graphConstraints = [NSLayoutConstraint]()
    
    var label = UILabel()
    var reloadLabel = UILabel()

    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        examples = Examples()
        graphView = examples.createMultiPlotGraphOne(view.frame)
        
        addReloadLabel(withText: "RELOAD")
        addLabel(withText: "MULTI 1")

        view.insertSubview(graphView, belowSubview: reloadLabel)
        
        setupConstraints()
    }
    
    // MARK: Constraints
    
    private func setupConstraints() {
        guard let graphView = graphView else { return }
        graphView.translatesAutoresizingMaskIntoConstraints = false
        graphConstraints = [
            graphView.topAnchor.constraint(equalTo: view.topAnchor),
            graphView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            graphView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            graphView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        ]
        NSLayoutConstraint.activate(graphConstraints)
    }
    
    // Adding and updating the graph switching label in the top right corner of the screen.
    private func addLabel(withText text: String) {
        
        label.removeFromSuperview()
        label = createLabel(withText: text)
        label.isUserInteractionEnabled = true
        
        let rightConstraint = label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        let topConstraint = label.topAnchor.constraint(equalTo: view.topAnchor, constant: 25)
        let heightConstraint = label.heightAnchor.constraint(equalToConstant: 30)
        let widthConstraint = label.widthAnchor.constraint(equalToConstant: label.frame.width * 1.5)
        
        let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(didTap))
        label.addGestureRecognizer(tapGestureRecogniser)
        
        view.insertSubview(label, aboveSubview: reloadLabel)
        NSLayoutConstraint.activate([rightConstraint, topConstraint, heightConstraint, widthConstraint])
    }
    
    private func addReloadLabel(withText text: String) {
        
        reloadLabel.removeFromSuperview()
        reloadLabel = createLabel(withText: text)
        reloadLabel.isUserInteractionEnabled = true
        
        let leftConstraint = reloadLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        let topConstraint = reloadLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 25)

        let heightConstraint = reloadLabel.heightAnchor.constraint(equalToConstant: 30)
        let widthConstraint = reloadLabel.widthAnchor.constraint(equalToConstant: reloadLabel.frame.width * 1.5)
        
        let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(reloadDidTap))
        reloadLabel.addGestureRecognizer(tapGestureRecogniser)
        
        view.insertSubview(reloadLabel, aboveSubview: graphView)
        NSLayoutConstraint.activate([leftConstraint, topConstraint, heightConstraint, widthConstraint])
    }


    private func createLabel(withText text: String) -> UILabel {
        let label = UILabel()
        
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        label.text = text
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        label.font = UIFont.boldSystemFont(ofSize: 14)
        
        label.layer.cornerRadius = 2
        label.clipsToBounds = true

        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        return label
    }
    
    // MARK: Button Taps
    
    @objc func didTap(_ gesture: UITapGestureRecognizer) {
        
        currentGraphType.next()
        
        view.removeConstraints(graphConstraints)
        graphView.removeFromSuperview()
        
        switch(currentGraphType) {
            
        case .simple: graphView = examples.createSimpleGraph(view.frame)
        case .multiOne: graphView = examples.createMultiPlotGraphOne(view.frame)
        case .multiTwo: graphView = examples.createMultiPlotGraphTwo(view.frame)
        case .dark: graphView = examples.createDarkGraph(view.frame)
        case .dot: graphView = examples.createDotGraph(view.frame)
        case .bar: graphView = examples.createBarGraph(view.frame)
        case .pink: graphView = examples.createPinkGraph(view.frame)
        case .blueOrange: graphView = examples.createBlueOrangeGraph(view.frame)
        }

        addReloadLabel(withText: "RELOAD")
        addLabel(withText: currentGraphType.title)

        view.insertSubview(graphView, belowSubview: reloadLabel)
        
        setupConstraints()
    }
    
    @objc func reloadDidTap(_ gesture: UITapGestureRecognizer) {
        examples.reload()
        graphView.reload()
    }
}

