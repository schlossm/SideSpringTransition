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
        container.present(viewController, animated: false)
        XCTAssertEqual(container.children, [viewController])
        XCTAssertEqual(container.trackedChildren, [viewController])
    }
    
    func testScreenEdge()
    {
        let container = MSTransitionContainerViewController()
        container.view.frame = CGRect(x: 0.0, y: 0.0, width: 414.0, height: 896.0)
        
        let viewController = UIViewController()
        container.present(viewController, animated: false)
        XCTAssertFalse(container.screenEdgeGesture.isEnabled)
        
        let nextVC = ScreenEdgeVC()
        container.present(nextVC, animated: false)
        XCTAssertFalse(container.screenEdgeGesture.isEnabled)
    }
    
    func testDismiss()
    {
        let container = MSTransitionContainerViewController()
        container.view.frame = CGRect(x: 0.0, y: 0.0, width: 414.0, height: 896.0)
        
        let expectation = self.expectation(description: "de-init")
        let viewController = UIViewController()
        container.present(viewController, animated: false)
        container.present(TrackedVC(expectation: expectation), animated: false)
        container.dismiss(animated: false)
        XCTAssertEqual(container.children, [viewController])
        XCTAssertEqual(container.trackedChildren, [viewController])
        wait(for: [expectation], timeout: 1.0)
    }
}

private class ScreenEdgeVC : UIViewController
{
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .left }
}

class TrackedVC : UIViewController
{
    let expectation: XCTestExpectation
    
    init(expectation: XCTestExpectation)
    {
        self.expectation = expectation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder)
    {
        fatalError()
    }
    
    deinit
    {
        expectation.fulfill()
    }
}
