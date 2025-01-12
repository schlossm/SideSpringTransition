//
//  MSTransitionContainerView.swift
//  MSTransition
//
//  Created by Michael Schloss on 10/1/20.
//  Copyright © 2020 Michael Schloss. All rights reserved.
//

import UIKit
import struct SwiftUI.Binding

enum HorizontalEdge
{
    case leading
    case trailing
}

/**
 A custom container view controller that transitions views in a side-by-side animation.
 
 The container contains built-in leading-edge gesture support.  This gesture functions the same as `UINavigationController`.
 */
private class MSTransitionNavigationController : UINavigationController
{
    init()
    {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    private func commonInit()
    {
        super.setNavigationBarHidden(true, animated: false)
    }
    
    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {}
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        super.setNavigationBarHidden(true, animated: false)
    }
}

public class MSTransitionContainerViewController : UIViewController, UINavigationControllerDelegate
{
    private let containerNavigationController = MSTransitionNavigationController()
    private lazy var transitionController = MSTransitionContainerAnimationCoordinator(navigationController: containerNavigationController, canDismissInteractive: { self.canDismissInteractive })
    
#if !os(tvOS)
    var screenEdgeGesture = UIScreenEdgePanGestureRecognizer()
    
    var canDismissInteractive = true
#endif
    
#if !os(tvOS)
    public override func setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    {
        super.setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
        canDismissInteractive = containerNavigationController.viewControllers.count > 1
        if let vc = containerNavigationController.viewControllers.last, vc.preferredScreenEdgesDeferringSystemGestures.contains(.left)
        {
            canDismissInteractive = false
        }
    }
#endif
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        containerNavigationController.delegate = transitionController
        
        containerNavigationController.willMove(toParent: self)
        addToContainer(containerNavigationController)
        containerNavigationController.didMove(toParent: self)
        
#if !os(tvOS)
        screenEdgeGesture.edges = [.left]
        screenEdgeGesture.addTarget(transitionController, action: #selector(MSTransitionContainerAnimationCoordinator.handleDismiss(swipeGesture:)))
        view.addGestureRecognizer(screenEdgeGesture)
#endif
    }
    
    /**
     Replaces the view controllers currently managed by the navigation controller with the specified items.
     
     Use this method to update or replace the current view controller stack without pushing or popping each controller explicitly. In addition, this method lets you update the set of controllers without animating the changes, which might be appropriate at launch time when you want to return the navigation controller to a previous state.
     
     If animations are enabled, this method decides which type of transition to perform based on whether the last item in the items array is already in the navigation stack. If the view controller is currently in the stack, but is not the topmost item, this method uses a pop transition; if it is the topmost item, no transition is performed. If the view controller is not on the stack, this method uses a push transition. Only one transition is performed, but when that transition finishes, the entire contents of the stack are replaced with the new view controllers. For example, if controllers A, B, and C are on the stack and you set controllers D, A, and B, this method uses a pop transition and the resulting stack contains the controllers D, A, and B.
     
     - Parameter viewControllers: The view controllers to place in the stack. The front-to-back order of the controllers in this array represents the new bottom-to-top order of the controllers in the navigation stack. Thus, the last item added to the array becomes the top item of the navigation stack.
     - Parameter animated: If true, animate the pushing or popping of the top view controller. If false, replace the view controllers without any animations.
     */
    public func setViewControllers(_ viewControllers: [UIViewController], animated flag: Bool)
    {
        containerNavigationController.setViewControllers(viewControllers, animated: flag)
    }
    
    /**
     Presents a view controller onto this container.
     
     Presentation follows the following rules:
     2. If the container currently has at least one view controller in its stack, a side-by-side transition occurs
     * If `animated` is false, the animations are skipped
     
     - Parameter child: The view controller to place in the container
     - Parameter animated: Whether or not the transition shows an animation
     */
    public func present(child viewController: UIViewController, animated flag: Bool = true)
    {
        containerNavigationController.pushViewController(viewController, animated: flag)
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }
    
    /**
     Dismisses a provided view controller
     
     The container animates the transition between the top view controller and the view controller in the stack underneath the provided view controller
         * If `animated` is false, the animations are skipped
     
     - Parameter child: An optionally provided view controller to dismiss
     - Parameter flag: Whether or not the transition shows an animation
     */
    public func dismiss(child viewController: UIViewController, animated flag: Bool = true)
    {
        guard let index = containerNavigationController.viewControllers.firstIndex(of: viewController) else { return }
        let viewController = containerNavigationController.viewControllers[max(index - 1, 0)]
        containerNavigationController.popToViewController(viewController, animated: flag)
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }
    
    /**
     Dismisses the currently presented view controller
     
     - Parameter flag: Whether or not the transition shows an animation
     */
    public func dismiss(animated flag: Bool = true)
    {
        containerNavigationController.popViewController(animated: flag)
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
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

private class MSTransitionContainerAnimationCoordinator : NSObject, UINavigationControllerDelegate
{
    private var interactiveTransition : DismissAnimator?
    
    private let navigationController : UINavigationController
    private let canDismissInteractive : () -> Bool
    
    private var isAnimating = false
    private var isInteractive = false
    
    init(navigationController: UINavigationController, canDismissInteractive : @escaping () -> Bool)
    {
        self.navigationController = navigationController
        self.canDismissInteractive = canDismissInteractive
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> (any UIViewControllerAnimatedTransitioning)?
    {
        isAnimating = true
        switch operation {
        case .none:
            return nil
        case .push:
            return PresentationAnimator()
        case .pop:
            interactiveTransition = DismissAnimator()
            return interactiveTransition
        @unknown default:
            return nil
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool)
    {
        isAnimating = false
        interactiveTransition = nil
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
        isInteractive ? interactiveTransition : nil
    }
    
    @objc fileprivate func handleDismiss(swipeGesture gestureRecognizer: UIScreenEdgePanGestureRecognizer)
    {
        guard let gestureRecognizerView = gestureRecognizer.view else {
            interactiveTransition = nil
            return
        }
        
        let percent = gestureRecognizer.translation(in: gestureRecognizerView).x / gestureRecognizerView.bounds.size.width
        
        switch gestureRecognizer.state
        {
        case .began:
            guard canDismissInteractive(), !isAnimating else { return }
            isInteractive = true
            navigationController.popViewController(animated: true)
            
        case .changed:
            interactiveTransition?.update(percent)
            
        case .ended:
            isInteractive = false
            let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
            let velocity = gestureRecognizer.velocity(in: gestureRecognizerView)
            let translation = gestureRecognizer.translation(in: gestureRecognizerView)
            let projectedPosition = CGPoint(
                x: translation.x + project(initialVelocity: velocity.x, decelerationRate: decelerationRate),
                y: translation.y + project(initialVelocity: velocity.y, decelerationRate: decelerationRate)
            )
            let nearestEdge = nearestHorizontalEdge(from: projectedPosition)
            let endPoint = nearestEdge == .leading ? 0 : navigationController.view.frame.width
            let relativeInitialVelocity = relativeVelocity(forVelocity: velocity.x, from: gestureRecognizer.translation(in: gestureRecognizerView).x, to: endPoint)
            switch nearestEdge
            {
            case .leading:
                interactiveTransition?.cancel(velocity: CGVector(dx: relativeInitialVelocity, dy: 0))
                interactiveTransition = nil
                
            case .trailing:
                interactiveTransition?.finish(velocity: CGVector(dx: relativeInitialVelocity, dy: 0))
                interactiveTransition = nil
            }
            
        case .cancelled:
            isInteractive = false
            interactiveTransition?.cancel()
            interactiveTransition = nil
            
        case .failed:
            isInteractive = false
            interactiveTransition = nil
            
        default: return
        }
    }
    
    // Distance travelled after decelerating to zero velocity at a constant rate.
    func project(initialVelocity: CGFloat, decelerationRate: CGFloat) -> CGFloat
    {
        return (initialVelocity / 1000.0) * decelerationRate / (1.0 - decelerationRate)
    }
    
    func nearestHorizontalEdge(from point: CGPoint) -> HorizontalEdge
    {
        let distanceFromLeadingEdge = point.x - 0
        let distanceFromTrailingEdge = navigationController.view.frame.width - point.x
        
        if distanceFromLeadingEdge < distanceFromTrailingEdge
        {
            return navigationController.traitCollection.layoutDirection != .rightToLeft ? .leading : .trailing
        }
        else
        {
            return navigationController.traitCollection.layoutDirection != .rightToLeft ? .trailing : .leading
        }
    }
    
    private func relativeVelocity(forVelocity velocity: CGFloat, from currentValue: CGFloat, to targetValue: CGFloat) -> CGFloat
    {
        guard currentValue - targetValue != 0 else { return 0 }
        return velocity / (targetValue - currentValue)
    }
}
