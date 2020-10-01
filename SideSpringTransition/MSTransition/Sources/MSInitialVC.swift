//
//  MSInitialVC.swift
//  MSTransition
//
//  Created by Michael Schloss on 6/16/16.
//  Copyright © 2017 Michael Schloss. All rights reserved.
//

open class MSInitialVC: UIViewController, UIViewControllerTransitioningDelegate, UIViewControllerPreviewingDelegate
{
    open var forceTouchRegisters = [UIViewControllerPreviewing]()
    
    fileprivate let transition = MSTransitionController.default.dismissalTransition
    
    override open func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        forceTouchRegisters.forEach { unregisterForPreviewing(withContext: $0) }
        forceTouchRegisters.removeAll()
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return MSTransitionController.default.presentationTransition
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return transition
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        return transition
    }
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        return nil
    }
    
    open func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController)
    {
        (viewControllerToCommit as? ForceTouchDelegate)?.addEdgePan()
        present(viewControllerToCommit, animated: false, completion: nil)
    }
}
