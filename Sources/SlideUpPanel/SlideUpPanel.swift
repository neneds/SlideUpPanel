//
//  SlideUpPanel.swift
//  CardViewAnimation
//
//  Created by mac on 30/10/18.
//  Copyright © 2018 DominatorVbN. All rights reserved.
//

import UIKit

public class SlideUpPanel: UIViewController {
    
    enum CardState {
        case expanded
        case collapsed
    }
    
    public var initialCornerRadius: Float = 0
    public var handleArea: UIView = UIView()
    public var handleAreaHeight: CGFloat = 20
    public var heightOffset: CGFloat = 0
    public var handleAreaColor: UIColor = UIColor.white
    public var handleBarColor: UIColor = UIColor.lightGray
    public var contentAreaBackgroundColor: UIColor = UIColor.white
    public var vc: UIViewController!
    public var contentArea: UIView = UIView()
    public var cardHeight: CGFloat = 600
    public var runningAnimations: [UIViewPropertyAnimator] = [UIViewPropertyAnimator]()
    public var cardVisible: Bool = false
    public var animationProgressWhenInterrupted: CGFloat = 0
    public var visualEffectView: UIVisualEffectView?
    public var visualEffectStyle: UIBlurEffect.Style = .dark
    public var isVisualEffectEnabled: Bool = false {
        didSet {
            if visualEffectView != nil {
                if isVisualEffectEnabled {
                    return
                } else {
                    visualEffectView?.removeFromSuperview()
                }
            } else {
                if isVisualEffectEnabled {
                    setupVisualEffectView()
                } else {
                    return
                }
            }
        }
    }
    
    var nextState: CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    public init(vc: UIViewController, cardHeight: CGFloat?, heightOffset: CGFloat = 0) {
        super.init(nibName: nil, bundle: nil)
        self.vc = vc
        self.heightOffset = heightOffset
        self.cardHeight = cardHeight != nil ? cardHeight! : getProportionalHeightForCard()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setUi()
        self.view.roundTopCorners(radius: CGFloat(initialCornerRadius))
    }
    
    public func setUi(){
        setHandleView()
        setContentArea()
        setupCard()
    }
    
    public func setHandleView(){
        self.view.addSubview(handleArea)
        handleArea.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: totalHandlerHeight())
        handleArea.backgroundColor = handleAreaColor
        let bar = UIView()
        handleArea.addSubview(bar)
        bar.backgroundColor = handleBarColor
        bar.frame = CGRect(x: self.handleArea.frame.midX - 40, y: totalHandlerHeight() / 2, width: 80, height: 4)
        bar.layer.cornerRadius = bar.frame.height / 2
        bar.layer.masksToBounds = true
    }
    
    public func setContentArea(){
        self.view.addSubview(contentArea)
        contentArea.frame = CGRect(x: 0, y: self.handleArea.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - totalHeight())
        contentArea.backgroundColor = contentAreaBackgroundColor
    }
    
    public func setupCard()  {
        self.view.frame = CGRect(x: 0, y: vc.view.frame.height - totalHeight(), width: vc.view.bounds.width, height: cardHeight)
        self.view.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SlideUpPanel.handleCardTap(recognizer:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SlideUpPanel.handleCardPan(recognizer:)))
        
        self.handleArea.addGestureRecognizer(tapGestureRecognizer)
        self.handleArea.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func setupVisualEffectView() {
        visualEffectView = UIVisualEffectView()
        visualEffectView?.frame = vc.view.frame
        if let visualEffectView = self.visualEffectView {
            vc.view.addSubview(visualEffectView)
        }
    }
    
    @objc
    public func handleCardTap(recognizer:UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            toggleCardState()
        default:
            break
        }
    }
    
    /// Toggle the current state of the card between colapsed/expanded
    public func toggleCardState() {
        animateTransitionIfNeeded(state: nextState, duration: 0.9)
    }
    
    @objc
    public func handleCardPan (recognizer:UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            let translation = recognizer.translation(in: self.handleArea)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
        
    }
    
    func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.view.frame.origin.y = self.vc.view.frame.height - self.cardHeight
                case .collapsed:
                    self.view.frame.origin.y = self.vc.view.frame.height - self.totalHeight()
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            animateVisualEffectView(state: state, duration: duration)
        }
    }
    
    private func animateVisualEffectView(state: CardState, duration: TimeInterval) {
        if isVisualEffectEnabled {
            guard let visualEffectView = self.visualEffectView else { return }
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    visualEffectView.effect = UIBlurEffect(style: self.visualEffectStyle)
                case .collapsed:
                    visualEffectView.effect = nil
                }
            }
            
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
        }
    }
    
    func startInteractiveTransition(state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    public func updateInteractiveTransition(fractionCompleted:CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    public func continueInteractiveTransition (){
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    
    public func setViewControllerAsContent(controller:UIViewController) {
        self.addChild(controller)
        contentArea.removeFromSuperview()
        self.view.addSubview(controller.view)
        controller.view.frame = CGRect(x: 0, y: self.handleArea.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - totalHeight())
    }
    
    /// Height of the handle, including safe area offset
    private func totalHandlerHeight() -> CGFloat {
        let safeAreaHeight = getSafeAreaHeightOffset()
        return handleAreaHeight + safeAreaHeight
    }
    
    /// Height of the handle, safe area and offset
    private func totalHeight() -> CGFloat {
        let safeAreaHeight = getSafeAreaHeightOffset()
        return handleAreaHeight + safeAreaHeight + heightOffset
    }
    
    private func getSafeAreaHeightOffset() -> CGFloat {
        return  vc.view.safeAreaInsets.bottom
    }
}


internal extension UIView {
    /// Round the view top corners and option to turn on clip to bounds
    func roundTopCorners(radius: CGFloat, clipToBounds: Bool = true) {
        self.layer.cornerRadius = radius
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.clipsToBounds = clipToBounds
    }
}

internal extension SlideUpPanel {
    /// Get current device screen height
    func currentDeviceHeight() -> CGFloat {
        let screenSize: CGRect = UIScreen.main.bounds
        let screenHeight = screenSize.height
        if screenHeight > 0 {
            return screenHeight
        } else {
            // Iphone 11 pro size, default
            return 812
        }
    }
    
    func getProportionalHeightForCard() -> CGFloat {
        let defaultSize: CGFloat = 545.0 // Default height for iPhone 11 pro
        let defaultScreenHeight: CGFloat = 812.0 // iPhone 11 pro screen height
        
        let currentDeviceScreenHeight = currentDeviceHeight()
        
        //Rule of three
        let multplied = currentDeviceScreenHeight * defaultSize
        return multplied / defaultScreenHeight
    }
}


