//
//  MSIntermediateVC.swift
//  MSTransition
//
//  Created by Michael Schloss on 6/16/16.
//  Copyright © 2017 Michael Schloss. All rights reserved.
//

import UIKit

@available(iOS, deprecated: 13.0, message: "Use MSTransitionContainerViewController instead")
@available(tvOS, deprecated: 13.0, message: "Use MSTransitionContainerViewController instead")
open class MSIntermediateVC: MSInitialVC
{
    #if os(iOS)
    fileprivate(set) public var edgePan : UIScreenEdgePanGestureRecognizer?
    #endif
    
    fileprivate let transition = MSTransitionController.default.dismissalTransition
    
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
    extension MSIntermediateVC : ForceTouchDelegate
    {
        @objc func dismiss(edgePan: UIScreenEdgePanGestureRecognizer)
        {
            guard edgePan.state == .began else { return }
            
            MSTransitionController.default.wantsInteractiveStart = true
            dismiss(animated: true, completion: nil)
        }
        
        func addEdgePan()
        {
            if let edge = self.edgePan
            {
                view.removeGestureRecognizer(edge)
            }
            let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(dismiss(edgePan:)))
            edgePan.edges = .left
            view.addGestureRecognizer(edgePan)
            dismissAnimationController?.panGestureRecognizer = edgePan
            self.edgePan = edgePan
        }
    }
#endif
