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
    @Environment(\.dismiss) private var dismiss
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
            content
        }
    }
    
    private var content : some View
    {
        ZStack
        {
            ZStack(alignment: .top)
            {
                Color.blue.ignoresSafeArea(.all)
                
                Text("Top Second")
            }
            
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
}

#Preview
{
    Second(flowController: nil)
}
