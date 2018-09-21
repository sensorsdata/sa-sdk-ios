//
//  SAValueTransformers.h
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
//  Copyright © 2015－2018 Sensors Data Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SAPassThroughValueTransformer : NSValueTransformer

@end

@interface SABOOLToNSNumberValueTransformer : NSValueTransformer

@end

@interface SACATransform3DToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface SACGAffineTransformToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface SACGColorRefToNSStringValueTransformer : NSValueTransformer

@end

@interface SACGPointToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface SACGRectToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface SACGSizeToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface SANSAttributedStringToNSDictionaryValueTransformer : NSValueTransformer

@end

@interface SANSNumberToCGFloatValueTransformer : NSValueTransformer

@end

__unused static id transformValue(id value, NSString *toType) {
    assert(value != nil);

    if ([value isKindOfClass:[NSClassFromString(toType) class]]) {
        return [[NSValueTransformer valueTransformerForName:@"SAPassThroughValueTransformer"] transformedValue:value];
    }

    NSString *fromType = nil;
    NSArray *validTypes = @[[NSString class], [NSNumber class], [NSDictionary class], [NSArray class], [NSNull class]];
    for (Class c in validTypes) {
        if ([value isKindOfClass:c]) {
            fromType = NSStringFromClass(c);
            break;
        }
    }

    assert(fromType != nil);
    NSValueTransformer *transformer = nil;
    NSString *forwardTransformerName = [NSString stringWithFormat:@"SA%@To%@ValueTransformer", fromType, toType];
    transformer = [NSValueTransformer valueTransformerForName:forwardTransformerName];
    if (transformer) {
        return [transformer transformedValue:value];
    }

    NSString *reverseTransformerName = [NSString stringWithFormat:@"SA%@To%@ValueTransformer", toType, fromType];
    transformer = [NSValueTransformer valueTransformerForName:reverseTransformerName];
    if (transformer && [[transformer class] allowsReverseTransformation]) {
        return [transformer reverseTransformedValue:value];
    }

    return [[NSValueTransformer valueTransformerForName:@"SAPassThroughValueTransformer"] transformedValue:value];
}
