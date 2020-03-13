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
    public var updatedCornerRadius: Float = 12
    public var isCornerRadiusAnimatorOn: Bool = false
    public var handleArea: UIView = UIView()
    public var handleAreaHeight: CGFloat = 20
    public var handleAreaColor: UIColor = UIColor.white
    public var handleBarColor: UIColor = UIColor.lightGray
    public var contentAreaBackgroundColor: UIColor = UIColor.white
    public var vc: UIViewController!
    public var contentArea: UIView = UIView()
    public var visualEffectView: UIVisualEffectView!
    public var cardHeight: CGFloat = 600
    public var runningAnimations: [UIViewPropertyAnimator] = [UIViewPropertyAnimator]()
    public var cardVisible: Bool = false
    public var animationProgressWhenInterrupted: CGFloat = 0
    
    var nextState: CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    public init(vc: UIViewController, cardHeight: CGFloat?) {
        super.init(nibName: nil, bundle: nil)
        self.vc = vc
        self.cardHeight = cardHeight != nil ? cardHeight! : 600
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setUi()
        self.view.layer.cornerRadius = CGFloat(initialCornerRadius)
    }
    
    public func setUi(){
        setHandleView()
        setContentArea()
        setupCard()
    }
    
    public func setHandleView(){
        self.view.addSubview(handleArea)
        handleArea.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: handleAreaHeight)
        handleArea.backgroundColor = handleAreaColor
        let bar = UIView()
        handleArea.addSubview(bar)
        bar.backgroundColor = handleBarColor
        bar.frame = CGRect(x: self.handleArea.frame.midX - 40, y: handleAreaHeight / 2, width: 80, height: 4)
        bar.layer.cornerRadius = bar.frame.height / 2
        bar.layer.masksToBounds = true
    }
    
    public func setContentArea(){
        self.view.addSubview(contentArea)
        contentArea.frame = CGRect(x: 0, y: self.handleArea.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - handleAreaHeight)
        contentArea.backgroundColor = contentAreaBackgroundColor
    }
    
    public func setupCard()  {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = vc.view.frame
        vc.view.addSubview(visualEffectView)
        self.view.frame = CGRect(x: 0, y: vc.view.frame.height - handleAreaHeight, width: vc.view.bounds.width, height: cardHeight)
        self.view.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SlideUpPanel.handleCardTap(recognizer:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SlideUpPanel.handleCardPan(recognizer:)))
        
        self.handleArea.addGestureRecognizer(tapGestureRecognizer)
        self.handleArea.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc
    public func handleCardTap(recognizer:UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
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
                    self.view.frame.origin.y = self.vc.view.frame.height - (self.handleAreaHeight + self.getSafeAreaHeightOffset())
                }
            }
            
            frameAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            
            if isCornerRadiusAnimatorOn {
                let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                    switch state {
                    case .expanded:
                        self.view.layer.cornerRadius = 12
                    case .collapsed:
                        self.view.layer.cornerRadius = CGFloat(self.initialCornerRadius)
                    }
                }
                
                cornerRadiusAnimator.startAnimation()
                runningAnimations.append(cornerRadiusAnimator)
            }
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
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
        controller.view.frame = CGRect(x: 0, y: self.handleArea.frame.maxY, width: self.view.frame.width, height: self.view.frame.height - handleAreaHeight)
    }
    
    private func getSafeAreaHeightOffset() -> CGFloat {
        let guide = view.safeAreaLayoutGuide
        return guide.layoutFrame.size.height
    }
}
