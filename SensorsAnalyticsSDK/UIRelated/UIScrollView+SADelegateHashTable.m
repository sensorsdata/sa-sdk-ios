//
// UIScrollView+SADelegateHashTable.m
// SensorsAnalyticsSDK
//
// Created by 陈玉国 on 2022/9/3.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIScrollView+SADelegateHashTable.h"
#import <objc/runtime.h>

static const void *kSATableViewDelegateHashTable = &kSATableViewDelegateHashTable;
static const void *kSACollectionViewDelegateHashTable = &kSACollectionViewDelegateHashTable;

static const void *kSATableViewExposureDelegateHashTable = &kSATableViewExposureDelegateHashTable;
static const void *kSACollectionViewExposureDelegateHashTable = &kSACollectionViewExposureDelegateHashTable;

@implementation UITableView (SADelegateHashTable)

- (void)setSensorsdata_delegateHashTable:(NSHashTable *)delegateHashTable {
    objc_setAssociatedObject(self, kSATableViewDelegateHashTable, delegateHashTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSHashTable *)sensorsdata_delegateHashTable {
    NSHashTable *delegateHashTable = objc_getAssociatedObject(self, kSATableViewDelegateHashTable);
    if (!delegateHashTable) {
        delegateHashTable = [NSHashTable weakObjectsHashTable];
        self.sensorsdata_delegateHashTable = delegateHashTable;
    }
    return delegateHashTable;
}

- (void)setSensorsdata_exposure_delegateHashTable:(NSHashTable *)sensorsdata_exposure_delegateHashTable {
    objc_setAssociatedObject(self, kSATableViewExposureDelegateHashTable, sensorsdata_exposure_delegateHashTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSHashTable *)sensorsdata_exposure_delegateHashTable {
    NSHashTable *exposureDelegateHashTable = objc_getAssociatedObject(self, kSATableViewExposureDelegateHashTable);
    if (!exposureDelegateHashTable) {
        exposureDelegateHashTable = [NSHashTable weakObjectsHashTable];
        self.sensorsdata_exposure_delegateHashTable = exposureDelegateHashTable;
    }
    return exposureDelegateHashTable;
}

@end

@implementation UICollectionView (SADelegateHashTable)

- (void)setSensorsdata_delegateHashTable:(NSHashTable *)delegateHashTable {
    objc_setAssociatedObject(self, kSACollectionViewDelegateHashTable, delegateHashTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSHashTable *)sensorsdata_delegateHashTable {
    NSHashTable *delegateHashTable = objc_getAssociatedObject(self, kSACollectionViewDelegateHashTable);
    if (!delegateHashTable) {
        delegateHashTable = [NSHashTable weakObjectsHashTable];
        self.sensorsdata_delegateHashTable = delegateHashTable;
    }
    return delegateHashTable;
}

- (void)setSensorsdata_exposure_delegateHashTable:(NSHashTable *)sensorsdata_exposure_delegateHashTable {
    objc_setAssociatedObject(self, kSACollectionViewExposureDelegateHashTable, sensorsdata_exposure_delegateHashTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSHashTable *)sensorsdata_exposure_delegateHashTable {
    NSHashTable *exposureDelegateHashTable = objc_getAssociatedObject(self, kSACollectionViewExposureDelegateHashTable);
    if (!exposureDelegateHashTable) {
        exposureDelegateHashTable = [NSHashTable weakObjectsHashTable];
        self.sensorsdata_exposure_delegateHashTable = exposureDelegateHashTable;
    }
    return exposureDelegateHashTable;
}

@end
