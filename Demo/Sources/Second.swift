//
//  Second.swift
//  MSTransitionDemo
//
//  Created by Michael Schloss on 12/8/24.
//  Copyright © 2024 Michael Schloss. All rights reserved.
//

import SwiftUI
import MSTransition

struct Second : View
{
    @Environment(\.msTransitionDismiss) private var dismiss
    @State private var isBackSwipeOn = true
    
    let flowController : FlowController?
    
    var body: some View
    {
        if #available(iOS 16.0, *)
        {
            content
            .defersSystemGestures(on: isBackSwipeOn ? [] : .leading)
        }
        else
        {
            
        }
    }
    
    private var content : some View
    {
        VStack(spacing: 32)
        {
            VStack(spacing: 8)
            {
                Text("Page Two")
                
                Button("Back")
                {
                    dismiss()
                }
            }
            
            if #available(iOS 16.0, *)
            {
                Toggle("Allow back-swipe gesture", isOn: $isBackSwipeOn)
                    .toggleStyle(.switch)
            }
        }
        .padding()
    }
}

#Preview
{
    Second(flowController: nil)
}
