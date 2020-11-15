//
//  ViewController.swift
//  SideSpringDemo
//
//  Created by Michael Schloss on 1/14/17.
//  Copyright © 2017 Michael Schloss. All rights reserved.
//

import UIKit
import MSTransition

class ViewController : UIViewController
{
    @IBAction private func next()
    {
        (parent as? MSTransitionContainerViewController)?.present(UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "second"))
    }
}
