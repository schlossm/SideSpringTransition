//
//  ViewController.swift
//  SideSpringDemo
//
//  Created by Michael Schloss on 1/14/17.
//  Copyright © 2017 Michael Schloss. All rights reserved.
//

import UIKit

class ViewController: SideSpringTransitionHomeVC
{
    @IBOutlet var nextButton: UIButton!
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        threeDTouchViews.append(registerForPreviewing(with: self, sourceView: nextButton))
    }

    @IBAction func next()
    {
        let nextVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "second")
        nextVC.transitioningDelegate = self
        nextVC.modalPresentationStyle = .custom
        present(nextVC, animated: true, completion: nil)
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController?
    {
        if previewingContext.sourceView == nextButton
        {
            let nextVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "second")
            nextVC.transitioningDelegate = self
            nextVC.modalPresentationStyle = .custom
            return nextVC
        }
        return nil
    }
}

