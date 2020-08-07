//
//  TabBarController.swift
//  
//
//  Created by Q Trang on 8/6/20.
//

import SwiftUI
import Combine
import SwiftUIMultiNavStack

public struct TabBarController: UIViewControllerRepresentable {
    public class Coordinator: NSObject, UITabBarControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
        var parent: TabBarController
        let didSelectIndex: ((Int) -> Void)?
        
        var selectedIndex = 0
        var navControllers: [String: UINavigationController] = [:]
        private var cancellable = Set<AnyCancellable>()
        
        init(_ parent: TabBarController, didSelectIndex: ((Int) -> Void)? = nil) {
            self.parent = parent
            self.didSelectIndex = didSelectIndex
        }
        
        public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
            let index = tabBarController.viewControllers!.firstIndex(of: viewController) ?? 0
            self.selectedIndex = index
            self.didSelectIndex?(index)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setupNavController(for: viewController, at: self.selectedIndex)
            }
        }
        
        public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
            return nil
        }
        
        public func setupNavController(for viewController: UIViewController, at index: Int) {
            if let nav = parent.navigationController(for: viewController),
                nav.delegate == nil {
                let stackId = parent.tabs[index].stackId
                self.navControllers[stackId] = nav
                parent.stacks.stacks[stackId]?.$cacheElement.sink(receiveValue: { (cacheElement) in
                    guard let activeStackId = self.parent.stacks.activeStack?.id,
                        activeStackId == stackId else {
                            return
                    }
                    
                    guard let nav = self.navControllers[activeStackId] else {
                        return
                    }
                    
                    guard nav.viewControllers.count > 1 ||
                        (self.parent.stacks.activeStack?.count ?? 0 > 0) else {
                            return
                    }
                    
                    guard let currentElement = self.parent.stacks.activeStack?.currentElement else {
                        nav.popToRootViewController(animated: true)
                        return
                    }
                    
                    if cacheElement == currentElement {
                        guard cacheElement?.element != nav.topViewController else {
                            return
                        }
                        
                        //This will hide the back button so it does not show up during push animation
                        currentElement.element.navigationItem.hidesBackButton = true
                        nav.pushViewController(currentElement.element, animated: true)
                    } else {
                        nav.popToViewController(currentElement.element, animated: true)
                    }
                })
                    .store(in: &cancellable)
                
                nav.interactivePopGestureRecognizer?.addTarget(self, action: #selector(handlePopGesture(_:)))
                nav.interactivePopGestureRecognizer?.delegate = nil
                nav.interactivePopGestureRecognizer?.isEnabled = true
                nav.delegate = self
            }
        }
        
        @objc func handlePopGesture(_ gesture: UIGestureRecognizer) {
            guard gesture.state == .ended else {
                return
            }
            
            let stackId = parent.tabs[selectedIndex].stackId
            _ = parent.stacks.stacks[stackId]?.pop()
        }
    }
    
    @EnvironmentObject private var stacks: NavigationStacks
    
    public let tabs: [MultiStackNavTabView.Tab<AnyView>]
    public let viewControllers: [UIViewController]
    public let didSelectIndex: ((Int) -> Void)?
    
    public init(tabs: [MultiStackNavTabView.Tab<AnyView>], viewControllers: [UIViewController], didSelectIndex: ((Int) -> Void)? = nil) {
        self.tabs = tabs
        self.viewControllers = viewControllers
        self.didSelectIndex = didSelectIndex
    }
    
    public func makeUIViewController(context: Context) -> UITabBarController {
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = viewControllers
        tabBarController.delegate = context.coordinator
        
        return tabBarController
    }
    
    public func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            context.coordinator.setupNavController(for: self.viewControllers[0], at: 0)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self, didSelectIndex: didSelectIndex)
    }
    
    private func navigationController(for viewController: UIViewController) -> UINavigationController? {
        if viewController is UINavigationController {
            return viewController as? UINavigationController
        }
        
        for child in viewController.children {
            if let nav = child as? UINavigationController {
                return nav
            } else if let nav = navigationController(for: child) {
                return nav
            }
        }
        
        return nil
    }
}

