//
// SAObjectSerializerConfig.m
// SensorsAnalyticsSDK
//
// Created by 雨晗 on 1/18/16.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
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


#import "SAClassDescription.h"
#import "SAObjectSerializerConfig.h"

@implementation SAObjectSerializerConfig {
    NSDictionary *_classes;
    NSDictionary *_enums;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSMutableDictionary *classDescriptions = [[NSMutableDictionary alloc] init];
        for (NSDictionary *d in dictionary[@"classes"]) {
            NSString *superclassName = d[@"superclass"];
            SAClassDescription *superclassDescription = superclassName ? classDescriptions[superclassName] : nil;
            
            // 构造一个类的描述信息
            SAClassDescription *classDescription = [[SAClassDescription alloc] initWithSuperclassDescription:superclassDescription dictionary:d];

            classDescriptions[classDescription.name] = classDescription;
        }
 
        _classes = [classDescriptions copy];
    }

    return self;
}

- (NSArray *)classDescriptions {
    return [_classes allValues];
}

- (SAClassDescription *)classWithName:(NSString *)name {
    return _classes[name];
}
@end
