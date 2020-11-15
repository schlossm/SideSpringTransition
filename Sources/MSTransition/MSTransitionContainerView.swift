//
//  MSTransitionContainerView.swift
//  MSTransition
//
//  Created by Michael Schloss on 10/1/20.
//  Copyright © 2020 Michael Schloss. All rights reserved.
//

import UIKit

/**
 A custom container view controller that transitions views in a side-by-side animation.
 
 The container contains built-in gesture support.  This gesture functions the same as `UINavigationController`
 */
public class MSTransitionContainerViewController : UIViewController
{
    // Order preserved
    private var _trackedChildren = [UIViewController]()
    private var trackedChildren: [UIViewController]
    {
        get { _trackedChildren }
        _modify
        {
            yield &_trackedChildren
            screenEdgeGesture.isEnabled = _trackedChildren.count > 1
        }
        set { _trackedChildren = newValue }
    }
    
    private var screenEdgeGesture = UIScreenEdgePanGestureRecognizer()
    private var activeAnimator : UIViewPropertyAnimator?
    
    public override var shouldAutomaticallyForwardAppearanceMethods: Bool { false }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        screenEdgeGesture.edges = [.left]
        screenEdgeGesture.addTarget(self, action: #selector(handleSwipe(gesture:)))
        view.addGestureRecognizer(screenEdgeGesture)
    }
    
    /**
     Presents a view controller onto this container.
     
     Presentation follows the following rules:
     1. If the container is currently empty, the provided view controller is placed on screen in the final position with no animation
     2. If the container currently has at least one view controller in its stack, a side-by-side transition occurs
         * If `animated` is false, the animations are skipped
     
     - Parameter viewControllerToPresent: The view controller to place in the container
     - Parameter animated: Whether or not the transition shows an animation.  If this is the first presentation in the container, the value of this parameter is ignored
     */
    public func present(_ viewControllerToPresent: UIViewController, animated: Bool = true)
    {
        viewControllerToPresent.beginAppearanceTransition(true, animated: trackedChildren.isEmpty ? false : animated)
        addToContainer(viewControllerToPresent)
        
        guard let from = trackedChildren.last else
        {
            trackedChildren = [viewControllerToPresent]
            viewControllerToPresent.didMove(toParent: self)
            viewControllerToPresent.endAppearanceTransition()
            return
        }
        trackedChildren.append(viewControllerToPresent)
        func finish()
        {
            self.view.isUserInteractionEnabled = true
            from.view.removeFromSuperview()
            from.removeFromParent()
            from.endAppearanceTransition()
            viewControllerToPresent.endAppearanceTransition()
            viewControllerToPresent.didMove(toParent: self)
            self.activeAnimator = nil
        }
        
        from.beginAppearanceTransition(false, animated: animated)
        view.isUserInteractionEnabled = false
        from.willMove(toParent: nil)
        if !animated
        {
            finish()
            return
        }
        viewControllerToPresent.view.transform = CGAffineTransform(translationX: view.bounds.width, y: 0.0)
        let animator = UIViewPropertyAnimator(duration: animated ? 0.5 : 0.0, dampingRatio: 1.0)
        { [self] in
            viewControllerToPresent.view.transform = .identity
            from.view.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0.0)
        }
        animator.addCompletion { _ in finish() }
        activeAnimator = animator
        animator.startAnimation()
    }
    
    /**
     Dismisses a provided view controller
     
     Dismissal follows the following rules:
     1. The top view controller cannot be dismissed, and if provided an `NSException` will be raised
     2. The optionally provided view controller must be within the container's stack, if not an `NSException` will be raised
     3. If no view controller is provided, the container will dismiss the currently-visible (top) view controller
         * If `animated` is false, the animations are skipped
     4. If a view controller is provided, the container animates the transition between the top view controller and the view controller in the stack underneath the provided view controller
         * If `animated` is false, the animations are skipped
     
     - Parameter viewController: An optionally provided view controller to dismiss
     - Parameter animated: Whether or not the transition shows an animation
     */
    public func dismiss(viewController: UIViewController? = nil, animated: Bool = true)
    {
        guard trackedChildren.count > 1 else { return }
        guard viewController != trackedChildren.first else
        {
            if let vc = viewController
            {
                withVaList([vc]) { NSException.raise(.invalidArgumentException, format: "Cannot dismiss %@, which is the top view controller in this container", arguments: $0) }
            }
            else
            {
                NSException(name: .invalidArgumentException, reason: "Cannot dismiss the top view controller in this container", userInfo: nil).raise()
            }
            return
        }
        if let vc = viewController
        {
            guard trackedChildren.contains(vc) else
            {
                withVaList([vc]) { NSException.raise(.invalidArgumentException, format: "Cannot dismiss %@, which is not in the container hierarchy", arguments: $0) }
                return
            }
        }
        let current = trackedChildren.last!
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0) { [self] in current.view.transform = .init(translationX: view.bounds.width, y: 0.0) }
        
        let index: Int = {
            if let vc = viewController
            {
                return trackedChildren.index(before: trackedChildren.firstIndex(of: vc)!)
            }
            else
            {
                return trackedChildren.endIndex - 2
            }
        }()
        let to = trackedChildren[index]
        addToContainer(to)
        to.beginAppearanceTransition(true, animated: animated)
        current.beginAppearanceTransition(false, animated: animated)
        if !animated
        {
            current.endAppearanceTransition()
            to.endAppearanceTransition()
            trackedChildren = Array(trackedChildren[0...index])
            return
        }
        
        to.view.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0.0)
        animator.addAnimations { to.view.transform = .identity }
        animator.addCompletion
        { [self] in
            switch $0
            {
            case .end:
                current.endAppearanceTransition()
                to.endAppearanceTransition()
                trackedChildren = Array(trackedChildren[0...index])
                
            case .start:
                current.beginAppearanceTransition(true, animated: animated)
                to.beginAppearanceTransition(false, animated: animated)
                current.endAppearanceTransition()
                to.endAppearanceTransition()
                
            default: break
            }
        }
        activeAnimator = animator
        animator.startAnimation()
    }
    
    @objc private func handleSwipe(gesture: UIScreenEdgePanGestureRecognizer)
    {
        switch gesture.state
        {
        case .began:
            dismiss()
            activeAnimator?.pauseAnimation()
            let locationX = gesture.translation(in: view).x
            activeAnimator?.fractionComplete = locationX / view.bounds.width
            
        case .changed:
            let locationX = gesture.translation(in: view).x
            activeAnimator?.fractionComplete = locationX / view.bounds.width
            
        case .ended:
            let velocityX = gesture.velocity(in: view).x
            let locationX = gesture.translation(in: view).x
            switch locationX
            {
            case 0 ..< view.bounds.width / 2.0:
                switch velocityX
                {
                case 100 ..< .infinity:
                    activeAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: activeAnimator!.fractionComplete)
                    
                case -.infinity ..< 100:
                    activeAnimator?.isReversed = true
                    activeAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: activeAnimator!.fractionComplete)
                    
                default: fatalError()
                }
                
            case view.bounds.width / 2.0 ..< .infinity:
                switch velocityX
                {
                case -100 ..< .infinity:
                    activeAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: activeAnimator!.fractionComplete)
                    
                case -.infinity ..< -100:
                    activeAnimator?.isReversed = true
                    activeAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: activeAnimator!.fractionComplete)
                    
                default: fatalError()
                }
                
            default: fatalError()
            }
            
        case .cancelled:
            activeAnimator?.isReversed = true
            activeAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: activeAnimator!.fractionComplete)
            
        default: break
        }
    }
    
    private func addToContainer(_ viewController: UIViewController)
    {
        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewController.view)
        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
