//
//  MSTransitionContainerViewTests.swift
//  
//
//  Created by Michael Schloss on 12/31/20.
//

import XCTest
@testable import MSTransition

class MSTransitionContainerViewTests : XCTestCase
{
    static var allTests = [
        ("testPresentation", testPresentation),
        ("testDismiss", testDismiss),
        ("testScreenEdge", testScreenEdge)
    ]
    
    func testPresentation()
    {
        let container = MSTransitionContainerViewController()
        container.view.frame = CGRect(x: 0.0, y: 0.0, width: 414.0, height: 896.0)
        
        let viewController = UIViewController()
        container.present(viewController)
        XCTAssertEqual(container.children, [viewController])
        XCTAssertEqual(container.trackedChildren, [viewController])
    }
    
    func testScreenEdge()
    {
        let container = MSTransitionContainerViewController()
        container.view.frame = CGRect(x: 0.0, y: 0.0, width: 414.0, height: 896.0)
        
        let viewController = UIViewController()
        container.present(viewController)
        XCTAssertFalse(container.screenEdgeGesture.isEnabled)
        
        let nextVC = ScreenEdgeVC()
        container.present(nextVC)
        XCTAssertFalse(container.screenEdgeGesture.isEnabled)
    }
    
    func testDismiss()
    {
        let container = MSTransitionContainerViewController()
        container.view.frame = CGRect(x: 0.0, y: 0.0, width: 414.0, height: 896.0)
        
        let viewController = UIViewController()
        container.present(viewController)
        
        let vc2 = UIViewController()
        container.present(vc2)
        container.dismiss(animated: false)
        XCTAssertEqual(container.children, [viewController])
        XCTAssertEqual(container.trackedChildren, [viewController])
    }
}

private class ScreenEdgeVC : UIViewController
{
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .left }
}
