//
//  FlowController.swift
//  SideSpringDemo
//
//  Created by Michael Schloss on 10/1/20.
//  Copyright © 2020 Michael Schloss. All rights reserved.
//

import UIKit
import MSTransition

class FlowController : UIViewController
{
    var container : MSTransitionContainerViewController!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let container = MSTransitionContainerViewController()
        view.addSubview(container.view)
        container.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        container.view.frame = view.bounds
        self.container = container
        
        container.present(UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "first"))
    }
}
