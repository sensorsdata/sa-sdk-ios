//
//  NSString.m
//  SensorsAnalyticsSDK
//
//  Created by 王灼洲 on 2017/7/6.
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import "NSString+HashCode.h"

@implementation NSString (HashCode)

- (int)sensorsdata_hashCode {
    int hash = 0;
    for (int i = 0; i<[self length]; i++) {
        NSString *s = [self substringWithRange:NSMakeRange(i, 1)];
        char *unicode = (char *)[s cStringUsingEncoding:NSUnicodeStringEncoding];
        int charactorUnicode = 0;
        size_t length = strlen(unicode);
        for (int n = 0; n < length; n ++) {
            charactorUnicode += (int)((unicode[n] & 0xff) << (n * sizeof(char) * 8));
        }
        hash = hash * 31 + charactorUnicode;
    }
    
    return hash;
}
@end
