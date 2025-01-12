//
//  First.swift
//  MSTransitionDemo
//
//  Created by Michael Schloss on 12/8/24.
//  Copyright © 2024 Michael Schloss. All rights reserved.
//

import MSTransition
import SwiftUI

struct First : View
{
    let flowController: FlowController?
    
    var body : some View
    {
        ZStack
        {
            ZStack(alignment: .top)
            {
                Color.red.edgesIgnoringSafeArea(.all)
                
                Text("Top")
            }
            
            VStack(spacing: 16)
            {
                Text("Page One")
                
                Button("Next")
                {
                    flowController?.goToSecondSwiftUIPage()
                }
            }
        }
    }
}

#Preview {
    First(flowController: nil)
}
