//
// SAViewElementInfo+AutoTrack.m
// SensorsAnalyticsSDK
//
// Created by  储强盛 on 2024/3/5.
// Copyright © 2015-2024 Sensors Data Co., Ltd. All rights reserved.
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

#import "SAViewElementInfo+AutoTrack.h"
#import "SAAutoTrackManager.h"

@implementation SAViewElementInfo (AutoTrack)

- (BOOL)isVisualView {
    if (!self.view.userInteractionEnabled || self.view.alpha <= 0.01 || self.view.isHidden) {
        return NO;
    }
    return [SAAutoTrackManager.defaultManager isGestureVisualView:self.view];
}

@end


@implementation SAAlertElementInfo (AutoTrack)

- (BOOL)isVisualView {
    return YES;
}

@end

#pragma mark - Menu Element Type
@implementation SAMenuElementInfo (AutoTrack)

- (BOOL)isVisualView {
    // 在 iOS 14 中, 应当圈选 UICollectionViewCell
    if ([self.view.superview isKindOfClass:UICollectionViewCell.class]) {
        return NO;
    }
    return YES;
}

@end
