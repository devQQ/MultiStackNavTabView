//
//  TabBarController.swift
//
//
//  Created by Q Trang on 8/6/20.
//

import SwiftUI
import SwiftUIMultiNavStack

public struct MultiStackNavTabView: View {
    public struct Tab<Content: View> {
        let content: Content
        let item: UITabBarItem
        let stackId: String
        
        public init(content: Content, item: UITabBarItem, stackId: String) {
            self.content = content
            self.item = item
            self.stackId = stackId
        }
        
        public init(@ViewBuilder _ content: @escaping () -> Content, title: String? = nil, image: UIImage? = nil, selectedImage: UIImage? = nil, stackId: String) {
            let item = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
            self.init(content: content(), item: item, stackId: stackId)
            
        }
        
        public init(@ViewBuilder _ content: @escaping () -> Content, title: String? = nil, image: UIImage? = nil, tag: Int, stackId: String) {
            let item = UITabBarItem(title: title, image: image, tag: tag)
            self.init(content: content(), item: item, stackId: stackId)
        }
    }
    
    @EnvironmentObject private var stacks: NavigationStacks
    
    public let tabs: [Tab<AnyView>]
    public let viewControllers: [UIHostingController<AnyView>]
    public let didSelectIndex: ((Int) -> Void)?
    public let animated: Bool
    public let isTranslucent: Bool
    public let removeNavBarBottomLine: Bool
    
    public init(tabs: [Tab<AnyView>], didSelectIndex: ((Int) -> Void)? = nil, animated: Bool = true, isTranslucent: Bool = false, removeNavBarBottomLine: Bool = false) {
        self.tabs = tabs
        self.viewControllers = tabs.map() {
            let vc = UIHostingController(rootView: $0.content)
            vc.tabBarItem = $0.item
            
            return vc
        }
        self.didSelectIndex = didSelectIndex
        self.animated = animated
        self.isTranslucent = isTranslucent
        self.removeNavBarBottomLine = removeNavBarBottomLine
    }
    
    public var body: some View {
        TabBarController(tabs: self.tabs, viewControllers: viewControllers, didSelectIndex: didSelectIndex, animated: animated, isTranslucent: isTranslucent, removeNavBarBottomLine: removeNavBarBottomLine)
            .edgesIgnoringSafeArea(.bottom)
            .environmentObject(self.stacks)
    }
}
