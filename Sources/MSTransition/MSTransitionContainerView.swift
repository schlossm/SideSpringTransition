//
//  MSTransitionContainerView.swift
//  MSTransition
//
//  Created by Michael Schloss on 10/1/20.
//  Copyright © 2020 Michael Schloss. All rights reserved.
//

import UIKit

public class MSTransitionContainerViewController : UIViewController
{
    // Order preserved
    private var trackedChildren = [UIViewController]()
    
    private var screenEdgeGesture = UIScreenEdgePanGestureRecognizer()
    private var activeAnimator : UIViewPropertyAnimator?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        screenEdgeGesture.edges = [.left]
        screenEdgeGesture.addTarget(self, action: #selector(handleSwipe(gesture:)))
        view.addGestureRecognizer(screenEdgeGesture)
    }
    
    public func present(_ viewControllerToPresent: UIViewController, animated: Bool = true)
    {
        addToContainer(viewControllerToPresent)
        
        guard let from = trackedChildren.last else
        {
            trackedChildren = [viewControllerToPresent]
            viewControllerToPresent.didMove(toParent: self)
            return
        }
        trackedChildren.append(viewControllerToPresent)
        func finish()
        {
            self.view.isUserInteractionEnabled = true
            from.view.removeFromSuperview()
            from.removeFromParent()
            from.didMove(toParent: nil)
            viewControllerToPresent.didMove(toParent: self)
            self.activeAnimator = nil
        }
        
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
    
    public func dismiss(viewController: UIViewController? = nil)
    {
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
        let current = trackedChildren.last!
        let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0) { [self] in current.view.transform = .init(translationX: view.bounds.width, y: 0.0) }
        
        let index: Int = {
            if let vc = viewController
            {
                return trackedChildren.index(before: trackedChildren.firstIndex { $0 == vc }!)
            }
            else
            {
                return trackedChildren.endIndex - 2
            }
        }()
        let to = trackedChildren[index]
        addToContainer(to)
        to.viewWillAppear(true)
        to.view.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0.0)
        animator.addAnimations { to.view.transform = .identity }
        animator.addCompletion
        { [self] in
            switch $0
            {
            case .end:
                current.viewDidDisappear(true)
                to.viewDidAppear(true)
                for vc in trackedChildren[(index + 1)..<trackedChildren.endIndex]
                {
                    vc.willMove(toParent: nil)
                    vc.view.removeFromSuperview()
                    vc.removeFromParent()
                    vc.didMove(toParent: nil)
                }
                trackedChildren = Array(trackedChildren[0...index])
                
            case .start:
                current.viewDidAppear(true)
                to.willMove(toParent: nil)
                to.view.removeFromSuperview()
                to.removeFromParent()
                to.didMove(toParent: nil)
                
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
            
        case .changed:
            let locationX = gesture.location(in: view).x
            activeAnimator?.fractionComplete = locationX / view.bounds.width
            
        case .ended:
            let velocityX = gesture.velocity(in: view).x
            let locationX = gesture.location(in: view).x
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
