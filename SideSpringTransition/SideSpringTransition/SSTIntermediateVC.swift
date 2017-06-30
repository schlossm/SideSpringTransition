//
//  SSTIntermediateVC.swift
//  SideSpringTransition
//
//  Created by Michael Schloss on 6/16/16.
//  Copyright © 2017 Michael Schloss. All rights reserved.
//

open class SideSpringTransitionIntermediateVC: SideSpringTransitionInitialVC, ForceTouchDelegate
{
    private(set) public var edgePan : UIScreenEdgePanGestureRecognizer!
    
    fileprivate let transition = SideSpringTransition()
    
    override open func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        addEdgePan()
    }
    
    @objc func dismiss(edgePan: UIScreenEdgePanGestureRecognizer)
    {
        guard edgePan.state == .began else { return }
        
        dismissAnimationController?.willBeginInteractively = true
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismiss()
    {
        dismissAnimationController?.willBeginInteractively = false
        dismiss(animated: true, completion: nil)
    }
    
    func addEdgePan()
    {
        if let edge = edgePan
        {
            view.removeGestureRecognizer(edge)
        }
        edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(dismiss(edgePan:)))
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)
        dismissAnimationController?.panGestureRecognizer = edgePan
    }
}
