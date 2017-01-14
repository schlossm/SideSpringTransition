//
//  SideSpringTransition.swift
//  Pentago
//
//  Created by Michael Schloss on 6/16/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

import UIKit

@objc protocol SideSpringTransitionDisplay
{
    @objc optional func performLastMinuteDisplay()
}

class ForwardSideSpringTransition: NSObject, UIViewControllerAnimatedTransitioning
{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 1.0/2.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let fromVC  = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC    = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let containerView = transitionContext.containerView
        
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        fromVC.view.frame   = transitionContext.finalFrame(for: fromVC)
        toVC.view.frame     = transitionContext.finalFrame(for: toVC)
        toVC.view.layoutIfNeeded()
        toVC.view.transform = CGAffineTransform(translationX: toVC.view.frame.size.width, y: 0.0)
        let timingFunction = UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: CGVector(dx: 1.0, dy: 0.0))
        let propertyAnimator = UIViewPropertyAnimator(duration: 1.0/3.0, timingParameters: timingFunction)
        propertyAnimator.isUserInteractionEnabled = false
        propertyAnimator.addAnimations {
            fromVC.view.transform   = CGAffineTransform(translationX: -toVC.view.frame.size.width, y: 0.0)
            toVC.view.transform     = CGAffineTransform.identity
        }
        
        propertyAnimator.addCompletion { (position) in
            guard position == .end else { transitionContext.completeTransition(false); return }
            
            UIApplication.shared.keyWindow!.addSubview(toVC.view)
            fromVC.view.transform = CGAffineTransform.identity
            transitionContext.completeTransition(true)
        }
        
        (toVC as? SideSpringTransitionDisplay)?.performLastMinuteDisplay?()
        propertyAnimator.startAnimation()
    }
}

class SideSpringTransition: NSObject
{
    internal var transitionDriver   : TransitionDriver!
    var panGestureRecognizer        : UIScreenEdgePanGestureRecognizer!
    
    var willBeginInteractively = true
}

extension SideSpringTransition : UIViewControllerAnimatedTransitioning
{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 1.0/2.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) { }
    
    func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating
    {
        return transitionDriver.transitionAnimator
    }
}

extension SideSpringTransition : UIViewControllerInteractiveTransitioning
{
    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning)
    {
        transitionDriver = TransitionDriver(context: transitionContext, panGestureRecognizer: panGestureRecognizer)
        
        if wantsInteractiveStart == false
        {
            transitionDriver.endInteraction()
        }
    }
    
    var wantsInteractiveStart: Bool
    {
        return willBeginInteractively
    }
}

class TransitionDriver : NSObject
{
    var transitionContext : UIViewControllerContextTransitioning
    var transitionAnimator: UIViewPropertyAnimator!
    
    fileprivate var currentVelocity : CGFloat!
    
    init(context: UIViewControllerContextTransitioning, panGestureRecognizer: UIScreenEdgePanGestureRecognizer)
    {
        transitionContext = context
        super.init()
        
        panGestureRecognizer.addTarget(self, action: #selector(TransitionDriver.updateInteraction(_:)))
        
        let timingFunction = UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: CGVector(dx: 0.0, dy: 1.0))
        transitionAnimator = UIViewPropertyAnimator(duration: 1.0/3.0, timingParameters: timingFunction)
        transitionAnimator.isUserInteractionEnabled = false
        
        transitionAnimator.addAnimations
            {
                self.myAnimateTransition(context)
        }
        
        transitionAnimator.addCompletion { (position) in
            let fromVC  = self.transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
            let toVC    = self.transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
            
            guard position == .end else
            {
                toVC.view.transform     = CGAffineTransform.identity
                fromVC.view.transform   = CGAffineTransform.identity
                self.transitionContext.completeTransition(false)
                return
            }
            
            UIApplication.shared.keyWindow!.addSubview(toVC.view)
            fromVC.view.removeFromSuperview()
            self.transitionContext.completeTransition(true)
        }
        
        let fromVC  = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC    = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let containerView = transitionContext.containerView
        
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        fromVC.view.frame   = transitionContext.finalFrame(for: fromVC)
        toVC.view.frame     = transitionContext.finalFrame(for: toVC)
        toVC.view.transform = CGAffineTransform(translationX: -toVC.view.frame.size.width, y: 0.0)
        containerView.layoutIfNeeded()
    }
    
    func myAnimateTransition(_ transitionContext: UIViewControllerContextTransitioning)
    {
        let fromVC  = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toVC    = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        fromVC.view.transform   = CGAffineTransform(translationX: toVC.view.frame.size.width, y: 0.0)
        toVC.view.transform     = CGAffineTransform.identity
    }
    
    func updateInteraction(_ fromGesture: UIScreenEdgePanGestureRecognizer)
    {
        switch fromGesture.state
        {
        case .changed:
             currentVelocity = fromGesture.translation(in: transitionContext.containerView).x
             let translation = fromGesture.translation(in: transitionContext.containerView)
             
             let percentComplete = transitionAnimator.fractionComplete + progressStepFor(translation)
             transitionAnimator.fractionComplete = percentComplete
             transitionContext.updateInteractiveTransition(percentComplete)
             
             fromGesture.setTranslation(CGPoint.zero, in: transitionContext.containerView)
            
        case .ended, .cancelled:
            endInteraction()
            
        default:
            break
        }
    }
    
    func endInteraction()
    {
        guard transitionContext.isInteractive else
        {
            transitionContext.finishInteractiveTransition()
            animate(to: .end)
            return
        }
        
        let completionPosition = self.completionPosition()
        if completionPosition == .end
        {
            transitionContext.finishInteractiveTransition()
        }
        else
        {
            transitionContext.cancelInteractiveTransition()
        }
        
        animate(to: completionPosition)
    }
    
    fileprivate func animate(to position: UIViewAnimatingPosition)
    {
        transitionAnimator.isReversed = (position == .start)
        
        if transitionAnimator.state == .inactive
        {
            transitionAnimator.startAnimation()
        }
        else
        {
            transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: position == .end ? (1.0 - transitionAnimator.fractionComplete) : transitionAnimator.fractionComplete)
        }
    }
    
    fileprivate func progressStepFor(_ translation: CGPoint) -> CGFloat
    {
        return translation.x/transitionContext.containerView.frame.size.width
    }
    
    fileprivate func completionPosition() -> UIViewAnimatingPosition
    {
        var shouldContinue : Bool
        
        if transitionAnimator.fractionComplete < 0.3
        {
            shouldContinue = currentVelocity > 5.0
        }
        else
        {
            shouldContinue = currentVelocity > -5.0
        }
        
        return shouldContinue ? .end : .start
    }
}
