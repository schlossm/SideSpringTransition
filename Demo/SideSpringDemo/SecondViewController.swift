//
//  SecondViewController.swift
//  SideSpringDemo
//
//  Created by Michael Schloss on 10/1/20.
//  Copyright © 2020 Michael Schloss. All rights reserved.
//

import UIKit
import MSTransition

class SecondViewController : UIViewController
{
    @IBAction private func dismiss()
    {
        (parent as? MSTransitionContainerViewController)?.dismiss()
    }
}
