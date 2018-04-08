# MSTransition
## A custom animated transition with edge panning
### For non-UINavigationController based view controllers

![Build Status](https://www.bitrise.io/app/040f60b50b86f501/status.svg?token=q1mKq6q0EykVMy8xb00-fQ)

![GIF](util/preview.gif)

## Installation
Simply drag the SideSpringTransition folder with the source code into your project, adding them to the proper targets.

## Use

`MSInitialVC`, `MSIntermediateVC` and `MSFinalVC` are meant to be subclassed.  While you can use them as concrete classes, they do not offer the flexibility of your own custom view controllers.

See the example code for details on how to use 3D Touch with `MSTransition`.