//
//  MSTransition+SwiftUI.swift
//  MSTransition
//
//  Created by Michael Schloss on 12/8/24.
//

import SwiftUI

@MainActor @preconcurrency public struct MSTransitionDismissAction
{
    /// Dismisses the view if it is currently presented.
    ///
    /// Don't call this method directly. SwiftUI calls it for you when you
    /// call the ``MSTransitionDismissAction`` structure that you get from the
    /// ``Environment``:
    ///
    ///     private struct Contents: View {
    ///         @Environment(\.msTransitionDismiss) private var dismiss
    ///
    ///         var body: some View {
    ///             Button("Done") {
    ///                 dismiss() // Implicitly calls dismiss.callAsFunction()
    ///             }
    ///         }
    ///     }
    ///
    /// For information about how Swift uses the `callAsFunction()` method to
    /// simplify call site syntax, see
    /// [Methods with Special Names](https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID622)
    /// in *The Swift Programming Language*.
    @MainActor @preconcurrency public func callAsFunction()
    {
        wrapper.dismissAction()
    }
    
    fileprivate struct MethodWrapper : @unchecked Sendable
    {
        fileprivate let dismissAction : () -> Void
        
        fileprivate init(dismissAction: @escaping () -> Void)
        {
            self.dismissAction = dismissAction
        }
    }
    
    nonisolated private let wrapper : MethodWrapper
    
    nonisolated package init(dismissAction: @escaping () -> Void)
    {
        self.wrapper = .init(dismissAction: dismissAction)
    }
}

extension EnvironmentValues
{
    /// An action that dismisses the current presentation.
    ///
    /// Use this environment value to get the ``MSTransitionDismissAction`` instance
    /// for the current ``Environment``. Then call the instance
    /// to perform the dismissal. You call the instance directly because
    /// it defines a ``MSTransitionDismissAction/callAsFunction()``
    /// method that Swift calls when you call the instance.
    ///
    /// You can use this action to dismiss a presentation on an ``MSTransitionContainerViewController``
    ///
    ///
    /// The specific behavior of the action depends on where you call it from.
    /// For example, you can create a button that calls the ``MSTransitionDismissAction``
    /// inside a view:
    ///
    ///     private struct Contents: View {
    ///         @Environment(\.msTransitionDismiss) private var dismiss
    ///
    ///         var body: some View {
    ///             Button("Done") {
    ///                 dismiss()
    ///             }
    ///         }
    ///     }
    ///
    ///
    /// The dismiss action has no effect on a view that isn't currently
    /// presented. If you need to query whether SwiftUI is currently presenting
    /// a view, read the ``EnvironmentValues/isPresented`` environment value.
    ///
    /// - Note: While the dismiss action can be used to a close window that you
    ///   create with ``WindowGroup`` or ``Window``, prefer
    ///   ``DismissWindowAction`` for that use case instead.
    @Entry @MainActor public var msTransitionDismiss : MSTransitionDismissAction = .init(dismissAction: {})
}

private struct MSTransitionHostingControllerBridge<T : View, U: UIHostingController<T>> : UIViewControllerRepresentable
{
    let hostingController : U
    
    func makeUIViewController(context: Context) -> U { hostingController }
    
    func updateUIViewController(_ uiViewController: U, context: Context) {}
}

private typealias MSTransitionHostingControllerContent<U : View, V : UIHostingController<U>> = ModifiedContent<MSTransitionHostingControllerBridge<U, V>, _EnvironmentKeyWritingModifier<MSTransitionDismissAction>>

private class MSTransitionHostingController<U : View, V : UIHostingController<U>> : UIHostingController<MSTransitionHostingControllerContent<U, V>>
{
    let hostingController : V
    
    override var preferredScreenEdgesDeferringSystemGestures : UIRectEdge { hostingController.preferredScreenEdgesDeferringSystemGestures }
    
    init(hostingController: V, container: MSTransitionContainerViewController)
    {
        self.hostingController = hostingController
        var dismissAction : (() -> Void)!
        super.init(rootView: MSTransitionHostingControllerBridge(hostingController: hostingController)
            .environment(\.msTransitionDismiss, .init(dismissAction: { dismissAction() })) as! MSTransitionHostingControllerContent<U, V>)
        dismissAction = { container.dismiss(viewController: self, animated: true) }
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public extension MSTransitionContainerViewController
{
    /**
     Presents a SwiftUI hosting controller onto this container.
     
     Presentation follows the following rules:
     1. If the container is currently empty, the provided view controller is placed on screen in the final position with no animation
     2. If the container currently has at least one view controller in its stack, a side-by-side transition occurs
         * If `animated` is false, the animations are skipped
     
     - Parameter viewControllerToPresent: The view controller to place in the container
     - Parameter animated: Whether or not the transition shows an animation.  If this is the first presentation in the container, the value of this parameter is ignored
     - Parameter onCompletion: The block to execute after the view controller is dismissed. This block has no return value and takes no parameters. You may specify nil for this parameter.
     */
    func present<T : View>(_ viewControllerToPresent: UIHostingController<T>, animated: Bool = true, onCompletion: (() -> Void)? = nil)
    {
        self.present(MSTransitionHostingController(hostingController: viewControllerToPresent, container: self) as UIViewController, animated: animated, onCompletion: onCompletion)
    }
}
