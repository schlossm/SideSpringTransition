//
//  FlowController.swift
//  SideSpringDemo
//
//  Created by Michael Schloss on 10/1/20.
//  Copyright © 2020 Michael Schloss. All rights reserved.
//

import UIKit
import SwiftUI
import MSTransition

class FlowController : UIViewController, UITabBarDelegate
{
    var container : MSTransitionContainerViewController!
    var tabBar: UITabBar!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let container = MSTransitionContainerViewController()
        container.beginAppearanceTransition(true, animated: false)
        container.willMove(toParent: self)
        addChild(container)
        view.addSubview(container.view)
        container.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        container.view.frame = view.bounds
        self.container = container
        container.didMove(toParent: self)
        container.endAppearanceTransition()
        
        let tabBar = UITabBar()
        tabBar.delegate = self
        tabBar.items = [
            .init(title: "UIKit", image: .init(systemName: "square.text.square.fill"), tag: 0),
            .init(title: "SwiftUI", image: .init(systemName: "swift"), tag: 1),
        ]
        tabBar.selectedItem = tabBar.items?.first
        
        view.addSubview(tabBar)
        tabBar.frame.origin = CGPoint(x: 0, y: view.frame.height - tabBar.frame.height)
        self.tabBar = tabBar
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        uiKitTab()
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        tabBar.frame = CGRect(x: 0, y: view.frame.height - view.safeAreaInsets.bottom - 49.0, width: view.frame.width, height: view.safeAreaInsets.bottom + 49.0)
    }
    
    func uiKitTab()
    {
        container.setViewControllers([UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "first")], animated: false)
    }
    
    func swiftUITab()
    {
        container.setViewControllers([UIHostingController(rootView: First(flowController: self))], animated: false)
    }
    
    func goToSecondSwiftUIPage()
    {
        container.present(child: UIHostingController(rootView: Second(flowController: self)))
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let index = tabBar.items?.firstIndex(of: item) else { fatalError() }
        if index == 0
        {
            uiKitTab()
        } else {
            swiftUITab()
        }
    }
}
