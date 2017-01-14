//
//  SideSpringTransitionVC.swift
//  Valued
//
//  Created by Michael Schloss on 1/11/17.
//  Copyright © 2017 Michael Schloss. All rights reserved.
//

import UIKit

class SideSpringTransitionVC: UIViewController, threeDTouchDelegate
{
    fileprivate var edgePan : UIScreenEdgePanGestureRecognizer!
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if edgePan == nil
        {
            edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(SideSpringTransitionVC.dismiss(edgePan:)))
            edgePan.edges = UIRectEdge.left
            view.addGestureRecognizer(edgePan)
            (transitioningDelegate?.animationController?(forDismissed: self) as? SideSpringTransition)?.panGestureRecognizer = edgePan
        }
    }
    
    func dismiss(edgePan: UIScreenEdgePanGestureRecognizer)
    {
        switch edgePan.state
        {
        case .began:
            (transitioningDelegate?.animationController?(forDismissed: self) as? SideSpringTransition)?.willBeginInteractively = true
            dismiss(animated: true, completion: nil)
            
        default: break
        }
    }
    
    @IBAction func dismiss()
    {
        (transitioningDelegate?.animationController?(forDismissed: self) as? SideSpringTransition)?.willBeginInteractively = false
        dismiss(animated: true, completion: nil)
    }
    
    func makeEdgePan()
    {
        view.removeGestureRecognizer(edgePan)
        edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(SideSpringTransitionVC.dismiss(edgePan:)))
        edgePan.edges = UIRectEdge.left
        view.addGestureRecognizer(edgePan)
        (transitioningDelegate?.animationController?(forDismissed: self) as? SideSpringTransition)?.panGestureRecognizer = edgePan
    }
}
