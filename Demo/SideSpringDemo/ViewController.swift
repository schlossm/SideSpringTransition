//
//  ViewController.swift
//  SideSpringDemo
//
//  Created by Michael Schloss on 1/14/17.
//  Copyright © 2017 Michael Schloss. All rights reserved.
//

import UIKit
import MSTransition

class ViewController: MSInitialVC
{
    @IBOutlet var nextButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        forceTouchRegisters.append(registerForPreviewing(with: self, sourceView: nextButton))
    }

    @IBAction func next()
    {
        present(secondVC, animated: true, completion: nil)
    }
    
    fileprivate var secondVC: UIViewController {
        let nextVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "second")
        nextVC.transitioningDelegate = self
        nextVC.modalPresentationStyle = .custom
        return nextVC
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        return previewingContext.sourceView == nextButton ? secondVC : nil
    }
}
