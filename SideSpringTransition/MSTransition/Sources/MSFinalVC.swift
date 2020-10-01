//
//  MSFinalVC.swift
//  MSTransition
//
//  Created by Michael Schloss on 6/16/16.
//  Copyright © 2017 Michael Schloss. All rights reserved.
//

open class MSFinalVC: UIViewController
{
    #if os(iOS)
    fileprivate(set) public var edgePan : UIScreenEdgePanGestureRecognizer!
    #endif
    
    override open func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        #if os(iOS)
            addEdgePan()
        #endif
    }
    
    @IBAction func dismiss()
    {
        #if os(iOS)
            if UserDefaults.standard.bool(forKey: HapticFeedbackDefault)
            {
                UISelectionFeedbackGenerator().selectionChanged()
            }
        #endif
        MSTransitionController.default.wantsInteractiveStart = false
        dismiss(animated: true, completion: nil)
    }
}

#if os(iOS)
    extension MSFinalVC : ForceTouchDelegate
    {
        @objc func dismiss(edgePan: UIScreenEdgePanGestureRecognizer)
        {
            guard edgePan.state == .began else { return }
            
            MSTransitionController.default.wantsInteractiveStart = true
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
#endif
