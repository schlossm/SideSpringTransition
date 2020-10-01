//
//  MSTransition.swift
//  MSTransition
//
//  Created by Michael Schloss on 6/16/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

import UIKit

public let HapticFeedbackDefault = "HapticFeedback"

protocol ForceTouchDelegate
{
    func addEdgePan()
}

public extension UIViewController
{
    var dismissAnimationController : SSTDismissalTransition?
    {
        return transitioningDelegate?.animationController?(forDismissed: self) as? InteractableTransition
    }
}

protocol LoadingIndicatorMoveable
{
	var loadingIndicatorPosition : CGPoint { get }
}

public protocol SSTDismissalTransition : UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning
{
    var willBeginInteractively : Bool { get set }
    
    #if os(iOS)
    var panGestureRecognizer : UIScreenEdgePanGestureRecognizer? { get set }
    #endif
}

public protocol SSTController
{
    static var `default` : SSTController { get }
    
    var wantsInteractiveStart : Bool { get set }
    
    var presentationTransition : UIViewControllerAnimatedTransitioning { get }
    
    var dismissalTransition : SSTDismissalTransition { get }
    
    var progressIndicator : UIView? { get set }
}

public final class MSTransitionController : SSTController
{
    public static var `default` : SSTController = MSTransitionController()
    
    private var forwardTransition = NonInteractableTransition()
    private var backwardsTransition = InteractableTransition()
    
    public var wantsInteractiveStart : Bool = false
    {
        didSet
        {
            dismissalTransition.willBeginInteractively = wantsInteractiveStart
        }
    }
    public private(set) var presentationTransition : UIViewControllerAnimatedTransitioning = NonInteractableTransition()
    public private(set) var dismissalTransition : SSTDismissalTransition = InteractableTransition()
    
    public var progressIndicator : UIView?
    {
        didSet
        {
            if progressIndicator?.superview?.classForCoder != UIWindow.classForCoder()
            {
                print("The progress indicator must be a subview of a UIWindow in order for the indicator to fluidly move between views")
            }
        }
    }
    
    private init() { }
}

private class NonInteractableTransition: NSObject, UIViewControllerAnimatedTransitioning
{
    var isReversed = false
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { return 0.5 }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        guard let fromVC = transitionContext.viewController(forKey: .from), let toVC = transitionContext.viewController(forKey: .to) else
        {
            print("The presenting view controller and/or presented view controller does not exist on the transition context.  Please make sure you are not dismissing or presenting a null view controller")
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        containerView.addSubview(fromVC.view)
        containerView.addSubview(toVC.view)
        fromVC.view.frame = transitionContext.finalFrame(for: fromVC)
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        containerView.layoutIfNeeded()
        
        toVC.view.transform = CGAffineTransform(translationX: (isReversed ? -1 : 1) * toVC.view.frame.width, y: 0.0)
        
        let propertyAnimator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: 1.0) {
            fromVC.view.transform = CGAffineTransform(translationX: (self.isReversed ? 1 : -1) * toVC.view.frame.width, y: 0.0)
            toVC.view.transform = .identity
            
            if let loadingIndicatorMoveable = toVC as? LoadingIndicatorMoveable
            {
                MSTransitionController.default.progressIndicator?.center = loadingIndicatorMoveable.loadingIndicatorPosition
            }
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
        
        fromVC.viewWillDisappear(true)
        propertyAnimator.startAnimation()
    }
}

private class InteractableTransition: NSObject, SSTDismissalTransition
{
    fileprivate var transitionDriver = TransitionDriver()
    var willBeginInteractively = true
    
    #if os(iOS)
    var panGestureRecognizer : UIScreenEdgePanGestureRecognizer?
    #endif
}

extension InteractableTransition
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

extension InteractableTransition
{
    public func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning)
    {
        #if os(iOS)
            transitionDriver.setup(context: transitionContext, andPanGesture: panGestureRecognizer)
        #elseif os(tvOS)
            transitionDriver.setup(context: transitionContext)
        #endif
        if wantsInteractiveStart == false
        {
            transitionDriver.endInteraction()
        }
    }
    
    public var wantsInteractiveStart: Bool
    {
        return willBeginInteractively
    }
}

private class TransitionDriver
{
    let transitionAnimator : UIViewPropertyAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0, animations: nil)
    #if os(iOS)
    var panGestureRecognizer : UIScreenEdgePanGestureRecognizer?
    #endif
    
    private var transitionContext : UIViewControllerContextTransitioning?
    private var currentVelocity : CGFloat = 0.0
    
    init() { }
    
    func setup(context: UIViewControllerContextTransitioning)
    {
        guard let fromVC = context.viewController(forKey: .from), let toVC = context.viewController(forKey: .to) else
        {
            print("The presenting view controller and/or presented view controller does not exist on the transition context.  Please make sure you are not dismissing or presenting a null view controller")
            return
        }
        transitionContext = context
        transitionAnimator.addAnimations { self.myAnimateTransition(context) }
        transitionAnimator.isUserInteractionEnabled = false
        transitionAnimator.addCompletion { position in self.transitionAnimationCompleted(position: position) }
        
        let containerView = context.containerView
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        fromVC.view.frame = context.finalFrame(for: fromVC)
        toVC.view.frame = context.finalFrame(for: toVC)
        toVC.view.transform = CGAffineTransform(translationX: -toVC.view.frame.width, y: 0.0)
        containerView.layoutIfNeeded()
        toVC.viewWillAppear(true)
    }
    
    #if os(iOS)
    func setup(context: UIViewControllerContextTransitioning, andPanGesture panGesture: UIScreenEdgePanGestureRecognizer?)
    {
        setup(context: context)
        
        panGesture?.addTarget(self, action: #selector(updateInteraction(_:)))
        panGestureRecognizer = panGesture
    }
    #endif
    
    func myAnimateTransition(_ transitionContext: UIViewControllerContextTransitioning)
    {
        let fromVC = transitionContext.viewController(forKey: .from)!
        let toVC = transitionContext.viewController(forKey: .to)!
        
        if let loadingIndicatorMoveable = toVC as? LoadingIndicatorMoveable
        {
            MSTransitionController.default.progressIndicator?.center = loadingIndicatorMoveable.loadingIndicatorPosition
        }
        
        fromVC.view.transform = CGAffineTransform(translationX: toVC.view.frame.width, y: 0.0)
        toVC.view.transform = .identity
    }
    
    fileprivate func transitionAnimationCompleted(position: UIViewAnimatingPosition)
    {
        guard let transitionContext = transitionContext, let fromVC = transitionContext.viewController(forKey: .from), let toVC = transitionContext.viewController(forKey: .to) else { return }
        
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
        self.transitionContext = nil
    }
    
    #if os(iOS)
    @objc func updateInteraction(_ fromGesture: UIScreenEdgePanGestureRecognizer)
    {
        guard let transitionContext = transitionContext else { return }
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
    #endif
    
    func endInteraction()
    {
        guard let transitionContext = transitionContext else { return }
        
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
    
    private func animate(to position: UIViewAnimatingPosition)
    {
        transitionAnimator.isReversed = (position == .start)
        transitionAnimator.state == .inactive ? transitionAnimator.startAnimation() : transitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
    
    private func completionPosition() -> UIViewAnimatingPosition
    {
        return (transitionAnimator.fractionComplete < 0.3 ? (currentVelocity > 5.0) : (currentVelocity > -5.0)) ? .end : .start
    }
}
