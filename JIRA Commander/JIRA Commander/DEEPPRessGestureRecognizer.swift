//
//  DEEPPRessGestureRecognizer.swift
//  JIRA Commander
//
//  Created by Tim Ordenewitz on 09.02.16.
//  Copyright © 2016 Tim Ordenewitz. All rights reserved.
//


import AudioToolbox
import UIKit.UIGestureRecognizerSubclass

// MARK: GestureRecognizer

class DeepPressGestureRecognizer: UIGestureRecognizer
{
    var vibrateOnDeepPress = true
    
    private var target : UIViewController
    private var _force: CGFloat = 0.0
    private var _xTouch: CGFloat = 0.0
    private var _yTouch: CGFloat = 00.0
    private var _point :CGPoint? = nil

    private var _maxForce: CGFloat = 0.0
    let threshold: CGFloat

    internal var force: CGFloat {get {return _force}}
    internal var xTouch: CGFloat {get {return _xTouch }}
    internal var yTouch: CGFloat {get {return _yTouch}}
    internal var point: CGPoint? {get {return _point}}


    
    required init(target: AnyObject?, action: Selector, threshold: CGFloat)
    {
        self.target = target as! UIViewController
        self.threshold = threshold

        super.init(target: target, action: action)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent)
    {
        if let touch = touches.first
        {
            if (touch.force >= threshold){
                handleTouch(.Began,touch: touch)
            }

        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent)
    {
        if let touch = touches.first
        {
            if (touch.force >= threshold){
                handleTouch(.Changed,touch: touch)
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent)
    {
        super.touchesEnded(touches, withEvent: event)
        if let touch = touches.first
        {
            handleTouch(.Ended,touch: touch)
        }
    }
    
    private func handleTouch(state: UIGestureRecognizerState, touch: UITouch)
    {
        self.state = state
        
        _force = touch.force / touch.maximumPossibleForce
        _point = touch.locationInView(nil)
        _xTouch = (_point?.x)!
        _yTouch = _point!.y
    }
    
    
    //This function is called automatically by UIGestureRecognizer when our state is set to .Ended. We want to use this function to reset our internal state.
    internal override func reset() {
        super.reset()
        
        _force = 0.0
    }
}

