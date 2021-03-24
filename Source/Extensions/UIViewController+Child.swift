//
// Copyright (c) 2019 Shakuro (https://shakuro.com/)
// Sergey Popov
//

import UIKit

extension UIViewController {

    /**
     Helper method to add child view controller.
     - parameter childViewController: target child view controller to be added.
     - parameter notifyAbouAppearanceTransition: If true will perform beginAppearanceTransition() and endAppearanceTransition().
     - parameter targetContainerView: container view, where child should be added.
     Should be in hierarchy of parent view controller's view.
     If `nil` - parent's view will be used.
     - parameter belowSubview: child will be added just below this view (among it's siblings).
     If `nil` - will be added as top subview.
     - parameter animationDuration: duration of animation (if any).
     - parameter animations: block for transition animations.
     If `nil` - whole process will not be animated.
     */
    public func addChildViewController(_ childViewController: UIViewController,
                                       notifyAboutAppearanceTransition: Bool,
                                       targetContainerView: UIView? = nil,
                                       belowSubview: UIView? = nil,
                                       animationDuration: TimeInterval = 0.25,
                                       animations: ((_ containerView: UIView, _ childView: UIView) -> Void)? = nil) {
        addChild(childViewController)

        let containerView: UIView = targetContainerView ?? view

        childViewController.view.frame = containerView.bounds
        childViewController.view.translatesAutoresizingMaskIntoConstraints = true
        childViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if notifyAboutAppearanceTransition {
            childViewController.beginAppearanceTransition(true, animated: animations != nil)
        }
        if let belowSubviewActual = belowSubview {
            containerView.insertSubview(childViewController.view, belowSubview: belowSubviewActual)
        } else {
            containerView.addSubview(childViewController.view)
        }
        if let realAnimations = animations {
            UIView.animate(
                withDuration: animationDuration,
                animations: {
                    realAnimations(containerView, childViewController.view)
            },
                completion: { (_) -> Void in
                    if notifyAboutAppearanceTransition {
                        childViewController.endAppearanceTransition()
                    }
                    childViewController.didMove(toParent: self)

            })
        } else {
            if notifyAboutAppearanceTransition {
                childViewController.endAppearanceTransition()
            }
            childViewController.didMove(toParent: self)

        }
    }

    /// Removes self from parent view controller
    ///
    /// - Parameter notifyAbouAppearanceTransition: If true will perform beginAppearanceTransition() and endAppearanceTransition().
    public func removeFromParentViewController(notifyAboutAppearanceTransition: Bool) {
        willMove(toParent: nil)
        if notifyAboutAppearanceTransition {
            beginAppearanceTransition(false, animated: false)
        }
        view.removeFromSuperview()
        if notifyAboutAppearanceTransition {
            endAppearanceTransition()
        }
        removeFromParent()
    }

}
