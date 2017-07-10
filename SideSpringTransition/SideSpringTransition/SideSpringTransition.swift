//
//  SideSpringTransition.swift
//  SideSpringTransition
//
//  Created by Michael Schloss on 6/16/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

import UIKit

@objc public protocol SideSpringTransitionDisplay
{
    @objc optional func performLastMinuteActions()
}

protocol ForceTouchDelegate
{
    func addEdgePan()
}

public extension UIViewController
{
    public var dismissAnimationController: SideSpringTransition?
    {
        return transitioningDelegate?.animationController?(forDismissed: self) as? SideSpringTransition
    }
}

class ForwardSideSpringTransition: NSObject, UIViewControllerAnimatedTransitioning
{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        guard let fromVC = transitionContext.viewController(forKey: .from), let toVC = transitionContext.viewController(forKey: .to) else
        {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        fromVC.view.frame = transitionContext.finalFrame(for: fromVC)
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        containerView.layoutIfNeeded()
        
        toVC.view.transform = CGAffineTransform(translationX: toVC.view.frame.width, y: 0.0)
        
        let propertyAnimator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: 1.0) {
            fromVC.view.transform = CGAffineTransform(translationX: -toVC.view.frame.width, y: 0.0)
            toVC.view.transform = .identity
        }
        propertyAnimator.isUserInteractionEnabled = false
        propertyAnimator.addCompletion {
            guard $0 == .end else
            {
                transitionContext.completeTransition(false)
                return
            }
            
            UIApplication.shared.keyWindow?.addSubview(toVC.view)
            fromVC.view.transform = .identity
            transitionContext.completeTransition(true)
            fromVC.view.removeFromSuperview()
            fromVC.viewDidDisappear(true)
        }
        
        (toVC as? SideSpringTransitionDisplay)?.performLastMinuteActions?()
        
        fromVC.viewWillDisappear(true)
        propertyAnimator.startAnimation()
    }
}

open class SideSpringTransition: NSObject
{
    var transitionDriver : TransitionDriver!
    var panGestureRecognizer : UIScreenEdgePanGestureRecognizer!
    
    open var willBeginInteractively = true
}

extension SideSpringTransition : UIViewControllerAnimatedTransitioning
{
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return 0.5
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) { }
    
    public func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating
    {
        return transitionDriver.transitionAnimator
    }
}

extension SideSpringTransition : UIViewControllerInteractiveTransitioning
{
    public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning)
    {
        transitionDriver = TransitionDriver(context: transitionContext, panGestureRecognizer: panGestureRecognizer)
        if wantsInteractiveStart == false
        {
            transitionDriver.endInteraction()
        }
    }
    
    public func animationEnded(_ transitionCompleted: Bool)
    {
        transitionDriver = nil
    }
    
    public var wantsInteractiveStart: Bool
    {
        return willBeginInteractively
    }
}

class TransitionDriver
{
    var transitionAnimator: UIViewPropertyAnimator
    
    fileprivate var transitionContext : UIViewControllerContextTransitioning!
    fileprivate var currentVelocity : CGFloat = 0.0
    
    init?(context: UIViewControllerContextTransitioning, panGestureRecognizer: UIScreenEdgePanGestureRecognizer)
    {
        guard let fromVC = context.viewController(forKey: .from), let toVC = context.viewController(forKey: .to) else
        {
            print("The presenting view controller and/or presented view controller does not exist on the transition context.  Please make sure you are not dismissing or presenting a null view controller")
            return nil
        }
        
        transitionContext = context
        
        transitionAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0, animations: { })
        transitionAnimator.addAnimations { [unowned self] in
            self.myAnimateTransition(context)
        }
        transitionAnimator.isUserInteractionEnabled = false
        transitionAnimator.addCompletion { [unowned self] position in
            self.transitionAnimationCompleted(position: position)
        }
        
        let containerView = context.containerView
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        
        fromVC.view.frame = context.finalFrame(for: fromVC)
        toVC.view.frame = context.finalFrame(for: toVC)
        toVC.view.transform = CGAffineTransform(translationX: -toVC.view.frame.width, y: 0.0)
        containerView.layoutIfNeeded()
        
        toVC.viewWillAppear(true)
        
        panGestureRecognizer.addTarget(self, action: #selector(updateInteraction(_:)))
    }
    
    func myAnimateTransition(_ transitionContext: UIViewControllerContextTransitioning)
    {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        
        fromVC.view.transform = CGAffineTransform(translationX: toVC.view.frame.width, y: 0.0)
        toVC.view.transform = .identity
    }
    
    fileprivate func transitionAnimationCompleted(position: UIViewAnimatingPosition)
    {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        
        guard position == .end else
        {
            toVC.view.transform = .identity
            fromVC.view.transform = .identity
            transitionContext.completeTransition(false)
            
            UIApplication.shared.keyWindow!.addSubview(fromVC.view)
            toVC.view.removeFromSuperview()
            return
        }
        
        UIApplication.shared.keyWindow!.addSubview(toVC.view)
        fromVC.view.removeFromSuperview()
            
        toVC.viewDidAppear(true)
        fromVC.viewDidDisappear(true)
        
        transitionContext.completeTransition(true)
        transitionContext = nil
    }
    
    @objc func updateInteraction(_ fromGesture: UIScreenEdgePanGestureRecognizer)
    {
        switch fromGesture.state
        {
        case .changed:
             currentVelocity = fromGesture.translation(in: transitionContext.containerView).x
             let translation = fromGesture.translation(in: transitionContext.containerView)
             
             let percentageChange = translation.x/transitionContext.containerView.frame.size.width
             
             let percentComplete = transitionAnimator.fractionComplete + percentageChange
             transitionAnimator.fractionComplete = percentComplete
             transitionContext.updateInteractiveTransition(percentComplete)
             
             fromGesture.setTranslation(.zero, in: transitionContext.containerView)
            
        case .ended, .cancelled, .failed:
            endInteraction()
            
        default: break
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
        completionPosition == .end ? transitionContext.finishInteractiveTransition() : transitionContext.cancelInteractiveTransition()
        
        animate(to: completionPosition)
    }
    
    fileprivate func animate(to position: UIViewAnimatingPosition)
    {
        transitionAnimator.isReversed = (position == .start)
        transitionAnimator.state == .inactive ? transitionAnimator.startAnimation() : transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
    
    fileprivate func completionPosition() -> UIViewAnimatingPosition
    {
        return (transitionAnimator.fractionComplete < 0.3 ? (currentVelocity > 5.0) : (currentVelocity > -5.0)) ? .end : .start
    }
}
