//
//  SideSpringTransitionHomeVC.swift
//  SideSpringDemo
//
//  Created by Michael Schloss on 1/14/17.
//  Copyright © 2017 Michael Schloss. All rights reserved.
//

import UIKit

protocol threeDTouchDelegate
{
    func makeEdgePan()
}

class SideSpringTransitionHomeVC: UIViewController, UIViewControllerTransitioningDelegate, UIViewControllerPreviewingDelegate
{
    var threeDTouchViews = [UIViewControllerPreviewing]()
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        for view in threeDTouchViews
        {
            unregisterForPreviewing(withContext: view)
        }
        threeDTouchViews = []
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    let transition = SideSpringTransition()
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return ForwardSideSpringTransition()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return transition
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        return transition
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        (viewControllerToCommit as? threeDTouchDelegate)?.makeEdgePan()
        present(viewControllerToCommit, animated: false, completion: nil)
    }
}
