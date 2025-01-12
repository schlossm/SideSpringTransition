//
//  MSTransitionSideTransition.swift
//  MSTransition
//
//  Created by Michael Schloss on 1/12/25.
//

import UIKit

class PresentationAnimator : NSObject, UIViewControllerAnimatedTransitioning
{
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return (transitionContext?.isAnimated ?? true) ? 0.5 : 0.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let toViewController = transitionContext.viewController(forKey: .to)!
        let fromViewController = transitionContext.viewController(forKey: .from)!
        
        toViewController.view.frame = transitionContext.finalFrame(for: toViewController)
        fromViewController.view.frame = transitionContext.initialFrame(for: fromViewController)
        transitionContext.containerView.addSubview(fromViewController.view)
        transitionContext.containerView.addSubview(toViewController.view)
        
        toViewController.view.transform = CGAffineTransform(translationX: toViewController.view.frame.width, y: 0)
        
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), timingParameters: UISpringTimingParameters(dampingRatio: 1.0))
        animator.addAnimations
        {
            toViewController.view.transform = .identity
            fromViewController.view.transform = CGAffineTransform(translationX: -fromViewController.view.frame.width, y: 0)
        }
        animator.addCompletion
        { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            toViewController.view.transform = .identity
            fromViewController.view.transform = .identity
        }
        animator.startAnimation()
    }
}

class DismissAnimator : UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning
{
    private var animator : UIViewPropertyAnimator!
    
    private func makeAnimatorIfNeeded(_ transitionContext: any UIViewControllerContextTransitioning)
    {
        guard animator == nil else { return }
        _animateTransition(using: transitionContext)
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval
    {
        return (transitionContext?.isAnimated ?? true) ? 0.5 : 0.0
    }
    
    func interruptibleAnimator(using transitionContext: any UIViewControllerContextTransitioning) -> any UIViewImplicitlyAnimating
    {
        makeAnimatorIfNeeded(transitionContext)
        return animator
    }
    
    override func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning)
    {
        makeAnimatorIfNeeded(transitionContext)
        animator.pauseAnimation()
    }
    
    override func update(_ percentComplete: CGFloat)
    {
        super.update(percentComplete)
        animator?.fractionComplete = percentComplete
    }
    
    func finish(velocity: CGVector)
    {
        super.finish()
        let duration = transitionDuration(using: nil)
        animator?.continueAnimation(withTimingParameters: UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: velocity), durationFactor: max(CGFloat(duration) * (1 - abs(animator!.fractionComplete)), 0.1))
    }
    
    func cancel(velocity: CGVector)
    {
        super.cancel()
        let duration = transitionDuration(using: nil)
        animator?.isReversed = true
        animator?.continueAnimation(withTimingParameters: UISpringTimingParameters(dampingRatio: 1.0, initialVelocity: velocity), durationFactor: max(CGFloat(duration) * (1 - abs(animator!.fractionComplete)), 0.1))
    }
    
    override func finish()
    {
        finish(velocity: .init(dx: 1, dy: 1))
    }
    
    override func cancel()
    {
        cancel(velocity: .init(dx: 1, dy: 1))
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        _animateTransition(using: transitionContext)
        animator.startAnimation()
    }
    
    private func _animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let toViewController = transitionContext.viewController(forKey: .to)!
        let fromViewController = transitionContext.viewController(forKey: .from)!
        
        toViewController.view.transform = .identity
        fromViewController.view.transform = .identity
        
        toViewController.view.frame = transitionContext.finalFrame(for: toViewController)
        transitionContext.containerView.addSubview(toViewController.view)
        
        toViewController.view.transform = CGAffineTransform(translationX: -toViewController.view.frame.width, y: 0)
        
        animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), timingParameters: UISpringTimingParameters(dampingRatio: 1.0))
        animator.addAnimations
        {
            toViewController.view.transform = .identity
            fromViewController.view.transform = CGAffineTransform(translationX: fromViewController.view.frame.width, y: 0)
        }
        animator.addCompletion
        { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            fromViewController.view.transform = .identity
        }
    }
}
