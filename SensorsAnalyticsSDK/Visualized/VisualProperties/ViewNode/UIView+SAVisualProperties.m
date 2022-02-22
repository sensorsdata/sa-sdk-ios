//
// UIView+SAVisualProperties.m
// SensorsAnalyticsSDK
//
// Created by 储强盛 on 2021/1/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+SAVisualProperties.h"
#import "SAVisualizedManager.h"
#import <objc/runtime.h>
#import "SAAutoTrackUtils.h"

static void *const kSAViewNodePropertyName = (void *)&kSAViewNodePropertyName;

#pragma mark -
@implementation UIView (SAVisualProperties)

- (void)sensorsdata_visualize_didMoveToSuperview {
    [self sensorsdata_visualize_didMoveToSuperview];

    [SAVisualizedManager.defaultManager.visualPropertiesTracker didMoveToSuperviewWithView:self];
}

- (void)sensorsdata_visualize_didMoveToWindow {
    [self sensorsdata_visualize_didMoveToWindow];

    [SAVisualizedManager.defaultManager.visualPropertiesTracker didMoveToWindowWithView:self];
}

- (void)sensorsdata_visualize_didAddSubview:(UIView *)subview {
    [self sensorsdata_visualize_didAddSubview:subview];

    [SAVisualizedManager.defaultManager.visualPropertiesTracker didAddSubview:subview];
}

- (void)sensorsdata_visualize_bringSubviewToFront:(UIView *)view {
    [self sensorsdata_visualize_bringSubviewToFront:view];
    if (view.sensorsdata_viewNode) {
        // 移动节点
        [self.sensorsdata_viewNode.subNodes removeObject:view.sensorsdata_viewNode];
        [self.sensorsdata_viewNode.subNodes addObject:view.sensorsdata_viewNode];
        
        // 兄弟节点刷新 Index
        [view.sensorsdata_viewNode refreshBrotherNodeIndex];
    }
}

- (void)sensorsdata_visualize_sendSubviewToBack:(UIView *)view {
    [self sensorsdata_visualize_sendSubviewToBack:view];
    if (view.sensorsdata_viewNode) {
        // 移动节点
        [self.sensorsdata_viewNode.subNodes removeObject:view.sensorsdata_viewNode];
        [self.sensorsdata_viewNode.subNodes insertObject:view.sensorsdata_viewNode atIndex:0];
        
        // 兄弟节点刷新 Index
        [view.sensorsdata_viewNode refreshBrotherNodeIndex];
    }
}

- (void)setSensorsdata_viewNode:(SAViewNode *)sensorsdata_viewNode {
    objc_setAssociatedObject(self, kSAViewNodePropertyName, sensorsdata_viewNode, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (SAViewNode *)sensorsdata_viewNode {
    // 自定义属性被关闭，就不再操作 viewNode
    if (!SAVisualizedManager.defaultManager.visualPropertiesTracker) {
        return nil;
    }
    return objc_getAssociatedObject(self, kSAViewNodePropertyName);
}

/// 刷新节点位置信息
- (void)sensorsdata_refreshIndex {
    if (self.sensorsdata_viewNode) {
        [self.sensorsdata_viewNode refreshIndex];
    }
}

@end

@implementation UITableViewCell(SAVisualProperties)

- (void)sensorsdata_visualize_prepareForReuse {
    [self sensorsdata_visualize_prepareForReuse];

    // 重用后更新 indexPath
    [self sensorsdata_refreshIndex];
}

@end

@implementation UICollectionViewCell(SAVisualProperties)

- (void)sensorsdata_visualize_prepareForReuse {
    [self sensorsdata_visualize_prepareForReuse];

    // 重用后更新 indexPath
    [self sensorsdata_refreshIndex];
}

@end


@implementation UITableViewHeaderFooterView(SAVisualProperties)

- (void)sensorsdata_visualize_prepareForReuse {
    [self sensorsdata_visualize_prepareForReuse];

    // 重用后更新 index
    [self sensorsdata_refreshIndex];
}

@end

@implementation UIWindow(SAVisualProperties)
- (void)sensorsdata_visualize_becomeKeyWindow {
    [self sensorsdata_visualize_becomeKeyWindow];

    [SAVisualizedManager.defaultManager.visualPropertiesTracker becomeKeyWindow:self];
}

@end


@implementation UITabBar(SAVisualProperties)
- (void)sensorsdata_visualize_setSelectedItem:(UITabBarItem *)selectedItem {
    BOOL isSwitchTab = self.selectedItem == selectedItem;
    [self sensorsdata_visualize_setSelectedItem:selectedItem];

    // 当前已经是选中状态，即未切换 tab 修改页面，不需更新
    if (!isSwitchTab) {
        return;
    }
    if (!SAVisualizedManager.defaultManager.visualPropertiesTracker) {
        return;
    }

    SAViewNode *tabBarNode = self.sensorsdata_viewNode;
    NSString *itemIndex = [NSString stringWithFormat:@"%lu", (unsigned long)[self.items indexOfObject:selectedItem]];
    for (SAViewNode *node in tabBarNode.subNodes) {
        // 只需更新切换 item 对应 node 页面名称即可
        if ([node isKindOfClass:SATabBarButtonNode.class] && [node.elementPosition isEqualToString:itemIndex]) {
            // 共用自定义属性查询队列，从而保证更新页面信息后，再进行属性元素遍历
            dispatch_async(SAVisualizedManager.defaultManager.visualPropertiesTracker.serialQueue, ^{
                [node refreshSubNodeScreenName];
            });
        }
    }
}

@end

#pragma mark -
@implementation UIView (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    if ([self isKindOfClass:NSClassFromString(@"RTLabel")]) {   // RTLabel:https://github.com/honcheng/RTLabel
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                return title;
            }
        }
        return nil;
    }
    if ([self isKindOfClass:NSClassFromString(@"YYLabel")]) {    // RTLabel:https://github.com/ibireme/YYKit
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                return title;
            }
        }
        return nil;
#pragma clang diagnostic pop
    }
    if ([SAAutoTrackUtils isKindOfRNView:self]) { // RN 元素，https://reactnative.dev
        NSString *content = [self.accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (content.length > 0) {
            return content;
        }
    }

    if ([self isKindOfClass:NSClassFromString(@"WXView")]) { // WEEX 元素，http://doc.weex.io/zh/docs/components/a.html
        NSString *content = [self.accessibilityValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (content.length > 0) {
            return content;
        }
    }

    if ([[self nextResponder] isKindOfClass:UITextField.class] && ![self isKindOfClass:UIButton.class]) {
        /* 兼容输入框的元素采集
         UITextField 本身是一个容器，包括 UITextField 的元素内容，文字是直接渲染到 view 的
         层级结构如下
         UITextField
            _UITextFieldRoundedRectBackgroundViewNeue
            UIFieldEditor（UIScrollView 的子类，只有编辑状态才包含此层，非编辑状态直接包含下面层级）
                _UITextFieldCanvasView 或 _UISearchTextFieldCanvasView 或 _UITextLayoutCanvasView（模拟器出现） (UIView 的子类)
            _UITextFieldClearButton (可能存在)
         */
        UITextField *textField = (UITextField *)[self nextResponder];
        return [textField sensorsdata_propertyContent];
    }
    if ([NSStringFromClass(self.class) isEqualToString:@"_UITextFieldCanvasView"] || [NSStringFromClass(self.class) isEqualToString:@"_UISearchTextFieldCanvasView"] || [NSStringFromClass(self.class) isEqualToString:@"_UITextLayoutCanvasView"]) {
        
        UITextField *textField = (UITextField *)[self nextResponder];
        do {
            if ([textField isKindOfClass:UITextField.class]) {
                return [textField sensorsdata_propertyContent];
            }
        } while ((textField = (UITextField *)[textField nextResponder]));
        
        return nil;
    }

    NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
    for (UIView *subview in self.subviews) {
        // 忽略隐藏控件
        if (subview.isHidden || subview.sensorsAnalyticsIgnoreView) {
            continue;
        }
        NSString *temp = subview.sensorsdata_propertyContent;
        if (temp.length > 0) {
            [elementContentArray addObject:temp];
        }
    }
    if (elementContentArray.count > 0) {
        return [elementContentArray componentsJoinedByString:@"-"];
    }
    
    return nil;
}

@end

@implementation UILabel (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    return self.text ?: super.sensorsdata_propertyContent;
}

@end

@implementation UIImageView (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    NSString *imageName = self.image.sensorsAnalyticsImageName;
    if (imageName.length > 0) {
        return [NSString stringWithFormat:@"%@", imageName];
    }
    return super.sensorsdata_propertyContent;
}

@end


@implementation UITextField (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
	/*  兼容 RN 中输入框  placeholder 采集
	 RCTUITextField，未输入元素内容， text 为 @""，而非 nil
	 */
    if (self.text.length > 0) {
        return self.text;
    }
    return self.placeholder;
    /*
     针对 UITextField，因为子元素最终仍会尝试向上遍历 nextResponder 使用 UITextField本身获取内容
     如果再遍历子元素获取内容，会造成死循环调用而异常
     */
}

@end

@implementation UITextView (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    return self.text ?: super.sensorsdata_propertyContent;
}

@end

@implementation UISearchBar (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    return self.text ?: super.sensorsdata_propertyContent;
}

@end

#pragma mark - UIControl

@implementation UIButton (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    NSString *text = self.titleLabel.text;
    if (!text) {
        text = super.sensorsdata_propertyContent;
    }
    return text;
}

@end

@implementation UISwitch (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    return self.on ? @"checked" : @"unchecked";
}

@end

@implementation UIStepper (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    return [NSString stringWithFormat:@"%g", self.value];
}

@end

@implementation UISegmentedControl (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    return  self.selectedSegmentIndex == UISegmentedControlNoSegment ? [super sensorsdata_propertyContent] : [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

@end

@implementation UIPageControl (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    return [NSString stringWithFormat:@"%ld", (long)self.currentPage];
}

@end

@implementation UISlider (PropertiesContent)

- (NSString *)sensorsdata_propertyContent {
    return [NSString stringWithFormat:@"%f", self.value];
}

@end
