//  SASwizzler.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (SAHelpers)

- (UIImage *)sa_snapshotImage;
- (UIImage *)sa_snapshotForBlur;
- (int)mp_fingerprintVersion;

- (NSString *)jjf_varA;
- (NSString *)jjf_varB;
- (NSString *)jjf_varC;
- (NSArray *)jjf_varSetD;
- (NSString *)jjf_varE;

@end

