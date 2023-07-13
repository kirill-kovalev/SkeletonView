//
//  Copyright SkeletonView. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UIView+SkeletonView.swift
//
//  Created by Juanpe Catalán on 19/8/21.

import UIKit

extension UIView {
    
    public func showSkeleton(
        skeletonConfig config: SkeletonConfig,
        notifyDelegate: Bool = true
    ) {
        _isSkeletonAnimated = config.animated
        
        if notifyDelegate {
            _flowDelegate = SkeletonFlowHandler()
            _flowDelegate?.willBeginShowingSkeletons(rootView: self)
        }
        
        recursiveShowSkeleton(skeletonConfig: config, root: self)
    }

    public func updateSkeleton(
        skeletonConfig config: SkeletonConfig,
        notifyDelegate: Bool = true
    ) {
        _isSkeletonAnimated = config.animated
        
        if notifyDelegate {
            _flowDelegate?.willBeginUpdatingSkeletons(rootView: self)
        }
        
        recursiveUpdateSkeleton(skeletonConfig: config, root: self)
    }

    func recursiveLayoutSkeletonIfNeeded(root: UIView? = nil) {

        if isSkeletonable, sk.isSkeletonActive {
            layoutSkeletonLayerIfNeeded()
            if let config = _currentSkeletonConfig, config.animated, !_isSkeletonAnimated {
                startSkeletonAnimation(config.animation)
            }
        }
        
        subviews.forEach({ subview in
            subview.recursiveLayoutSkeletonIfNeeded()
        })

        if let root = root {
            _flowDelegate?.didLayoutSkeletonsIfNeeded(rootView: root)
        }
    }

    func recursiveHideSkeleton(reloadDataAfter reload: Bool, transition: SkeletonTransitionStyle, root: UIView? = nil) {
        if sk.isSkeletonActive {
            if isHiddenWhenSkeletonIsActive {
                isHidden = false
            }
            _currentSkeletonConfig?.transition = transition
            unSwizzleLayoutSubviews()
            unSwizzleTraitCollectionDidChange()
        }

        if _skeletonLayer != nil {
            recoverViewState(forced: false)
            removeSkeletonLayer()
        }
        
        subviews.forEach({
            $0.recursiveHideSkeleton(reloadDataAfter: reload, transition: transition)
        })
        
        if sk.isSkeletonActive {
            removeDummyDataSourceIfNeeded(reloadAfter: reload)
            
            
            if let root = root {
                _flowDelegate?.didHideSkeletons(rootView: root)
            }
        }
    }
    
}

private extension UIView {
    
    func showSkeletonIfNotActive(skeletonConfig config: SkeletonConfig) {
        guard !sk.isSkeletonActive else { return }
        saveViewState()

        prepareViewForSkeleton()
        addSkeletonLayer(skeletonConfig: config)
    }
    
    func recursiveShowSkeleton(skeletonConfig config: SkeletonConfig, root: UIView? = nil) {
            if isHiddenWhenSkeletonIsActive {
                isHidden = true
            }
            guard !sk.isSkeletonActive else { return }
            _currentSkeletonConfig = config
            swizzleLayoutSubviews()
            swizzleTraitCollectionDidChange()
            addDummyDataSourceIfNeeded()
            

            if self.isSkeletonable, !(self is CollectionSkeleton) {
                showSkeletonIfNotActive(skeletonConfig: config)
            }
            
            if !self.isSkeletonable || self is CollectionSkeleton {
                subviews.forEach({
                    $0.recursiveShowSkeleton(skeletonConfig: config)
                })
            }

            if let root = root {
                _flowDelegate?.didShowSkeletons(rootView: root)
            }
        }
    
    func recursiveUpdateSkeleton(skeletonConfig config: SkeletonConfig, root: UIView? = nil) {
        guard sk.isSkeletonActive else { return }
        _currentSkeletonConfig = config
        updateDummyDataSourceIfNeeded()
        subviewsSkeletonables.recursiveSearch(leafBlock: {
            if let skeletonLayer = _skeletonLayer,
                skeletonLayer.type != config.type {
                removeSkeletonLayer()
                addSkeletonLayer(skeletonConfig: config)
            } else {
                updateSkeletonLayer(skeletonConfig: config)
            }
        }) { subview in
            subview.recursiveUpdateSkeleton(skeletonConfig: config)
        }

        if let root = root {
            _flowDelegate?.didUpdateSkeletons(rootView: root)
        }
    }
    
}
