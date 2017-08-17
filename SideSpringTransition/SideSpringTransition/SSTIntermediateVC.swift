//
//  SSTIntermediateVC.swift
//  SideSpringTransition
//
//  Created by Michael Schloss on 6/16/16.
//  Copyright © 2017 Michael Schloss. All rights reserved.
//

#if os(iOS)
    open class SideSpringTransitionIntermediateVC: SideSpringTransitionInitialVC, ForceTouchDelegate
    {
        private(set) public var edgePan : UIScreenEdgePanGestureRecognizer!
        
        fileprivate let transition = SideSpringTransition()
        
        override open func viewWillAppear(_ animated: Bool)
        {
            super.viewWillAppear(animated)
            addEdgePan()
        }
        
        @objc func dismiss(edgePan: UIScreenEdgePanGestureRecognizer)
        {
            guard edgePan.state == .began else { return }
            
            dismissAnimationController?.willBeginInteractively = true
            dismiss(animated: true, completion: nil)
        }
        
        @IBAction func dismiss()
        {
            if UserDefaults.standard.bool(forKey: HapticFeedbackDefault)
            {
                UISelectionFeedbackGenerator().selectionChanged()
            }
            dismissAnimationController?.willBeginInteractively = false
            dismiss(animated: true, completion: nil)
        }
        
        func addEdgePan()
        {
            if let edge = edgePan
            {
                view.removeGestureRecognizer(edge)
            }
            edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(dismiss(edgePan:)))
            edgePan.edges = .left
            view.addGestureRecognizer(edgePan)
            dismissAnimationController?.panGestureRecognizer = edgePan
        }
    }
#elseif os(tvOS)
    open class SideSpringTransitionIntermediateVC: SideSpringTransitionInitialVC
    {
        fileprivate let transition = SideSpringTransition()
        
        override open func viewWillAppear(_ animated: Bool)
        {
            super.viewWillAppear(animated)
        }
        
        @IBAction func dismiss()
        {
            dismissAnimationController?.willBeginInteractively = false
            dismiss(animated: true, completion: nil)
        }
        
        open override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?)
        {
            guard presses.contains(where: { $0.type == .menu }) else
            {
                super.pressesEnded(presses, with: event)
                return
            }
            dismiss()
        }
    }
#endif