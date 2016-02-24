//
//  SAValueTransformers.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
//  Copyright (c) 2016年 SensorsData. All rights reserved.
//
///  Created by Alex Hofsteede on 5/5/14.
///  Copyright (c) 2014 Mixpanel. All rights reserved.
//

#import "SALogger.h"
#import "SAValueTransformers.h"

#pragma mark -- PassThrough

@implementation SAPassThroughValueTransformer

+ (Class)transformedValueClass {
    return [NSObject class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if ([[NSNull null] isEqual:value]) {
        return nil;
    }
    
    if (value == nil) {
        return [NSNull null];
    }
    
    return value;
}

@end

#pragma mark -- BOOL To NSNumber

@implementation SABOOLToNSNumberValueTransformer

+ (Class)transformedValueClass {
    return [@YES class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue] ? @YES : @NO;
    }
    
    return nil;
}

@end

#pragma mark -- CATransform3D To NSDictionary

static NSDictionary *MPCATransform3DCreateDictionaryRepresentation(CATransform3D transform) {
    return @{
             @"m11" : @(transform.m11),
             @"m12" : @(transform.m12),
             @"m13" : @(transform.m13),
             @"m14" : @(transform.m14),
             
             @"m21" : @(transform.m21),
             @"m22" : @(transform.m22),
             @"m23" : @(transform.m23),
             @"m24" : @(transform.m24),
             
             @"m31" : @(transform.m31),
             @"m32" : @(transform.m32),
             @"m33" : @(transform.m33),
             @"m34" : @(transform.m34),
             
             @"m41" : @(transform.m41),
             @"m42" : @(transform.m42),
             @"m43" : @(transform.m43),
             @"m44" : @(transform.m44),
             };
}

static BOOL MPCATransform3DMakeWithDictionaryRepresentation(NSDictionary *dictionary, CATransform3D *transform) {
    if (transform) {
        id m11 = dictionary[@"m11"];
        id m12 = dictionary[@"m12"];
        id m13 = dictionary[@"m13"];
        id m14 = dictionary[@"m14"];
        
        id m21 = dictionary[@"m21"];
        id m22 = dictionary[@"m22"];
        id m23 = dictionary[@"m23"];
        id m24 = dictionary[@"m24"];
        
        id m31 = dictionary[@"m31"];
        id m32 = dictionary[@"m32"];
        id m33 = dictionary[@"m33"];
        id m34 = dictionary[@"m34"];
        
        id m41 = dictionary[@"m41"];
        id m42 = dictionary[@"m42"];
        id m43 = dictionary[@"m43"];
        id m44 = dictionary[@"m44"];
        
        if (m11 && m12 && m13 && m14 &&
            m21 && m22 && m23 && m24 &&
            m31 && m32 && m33 && m34 &&
            m41 && m42 && m43 && m44)
        {
            transform->m11 = (CGFloat)[m11 doubleValue];
            transform->m12 = (CGFloat)[m12 doubleValue];
            transform->m13 = (CGFloat)[m13 doubleValue];
            transform->m14 = (CGFloat)[m14 doubleValue];
            
            transform->m21 = (CGFloat)[m21 doubleValue];
            transform->m22 = (CGFloat)[m22 doubleValue];
            transform->m23 = (CGFloat)[m23 doubleValue];
            transform->m24 = (CGFloat)[m24 doubleValue];
            
            transform->m31 = (CGFloat)[m31 doubleValue];
            transform->m32 = (CGFloat)[m32 doubleValue];
            transform->m33 = (CGFloat)[m33 doubleValue];
            transform->m34 = (CGFloat)[m34 doubleValue];
            
            transform->m41 = (CGFloat)[m41 doubleValue];
            transform->m42 = (CGFloat)[m42 doubleValue];
            transform->m43 = (CGFloat)[m43 doubleValue];
            transform->m44 = (CGFloat)[m44 doubleValue];
            
            return YES;
        }
    }
    
    return NO;
}

@implementation SACATransform3DToNSDictionaryValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(CATransform3DValue)]) {
        return MPCATransform3DCreateDictionaryRepresentation([value CATransform3DValue]);
    }

    return @{};
}

- (id)reverseTransformedValue:(id)value {
    CATransform3D transform = CATransform3DIdentity;
    if ([value isKindOfClass:[NSDictionary class]] && MPCATransform3DMakeWithDictionaryRepresentation(value, &transform)) {
        return [NSValue valueWithCATransform3D:transform];
    }
    
    return [NSValue valueWithCATransform3D:CATransform3DIdentity];
}

@end

#pragma mark -- CGAffineTransform To NSDictionary

static NSDictionary *MPCGAffineTransformCreateDictionaryRepresentation(CGAffineTransform transform) {
    return @{
             @"a" : @(transform.a),
             @"b" : @(transform.b),
             @"c" : @(transform.c),
             @"d" : @(transform.d),
             @"tx" : @(transform.tx),
             @"ty" : @(transform.ty)
             };
}

static BOOL MPCGAffineTransformMakeWithDictionaryRepresentation(NSDictionary *dictionary, CGAffineTransform *transform) {
    if (transform) {
        id a = dictionary[@"a"];
        id b = dictionary[@"b"];
        id c = dictionary[@"c"];
        id d = dictionary[@"d"];
        id tx = dictionary[@"tx"];
        id ty = dictionary[@"ty"];
        
        if (a && b && c && d && tx && ty) {
            transform->a = (CGFloat)[a doubleValue];
            transform->b = (CGFloat)[b doubleValue];
            transform->c = (CGFloat)[c doubleValue];
            transform->d = (CGFloat)[d doubleValue];
            transform->tx = (CGFloat)[tx doubleValue];
            transform->ty = (CGFloat)[ty doubleValue];
            
            return YES;
        }
    }
    
    return NO;
}

@implementation SACGAffineTransformToNSDictionaryValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(CGAffineTransformValue)]) {
        return MPCGAffineTransformCreateDictionaryRepresentation([value CGAffineTransformValue]);
    }
    
    return @{};
}

- (id)reverseTransformedValue:(id)value {
    CGAffineTransform transform = CGAffineTransformIdentity;
    if ([value isKindOfClass:[NSDictionary class]] && MPCGAffineTransformMakeWithDictionaryRepresentation(value, &transform)) {
        return [NSValue valueWithCGAffineTransform:transform];
    }
    
    return [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
}

@end

#pragma mark -- CGColorRef To NSString

@implementation SACGColorRefToNSStringValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
    if (value && CFGetTypeID((__bridge CFTypeRef)value) == CGColorGetTypeID()) {
        NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:@"MPUIColorToNSStringValueTransformer"];
        return [transformer transformedValue:[[UIColor alloc] initWithCGColor:(__bridge CGColorRef)value]];
    }
    
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    NSValueTransformer *transformer = [NSValueTransformer valueTransformerForName:@"MPUIColorToNSStringValueTransformer"];
    UIColor *uiColor =  [transformer reverseTransformedValue:value];
    return CFBridgingRelease(CGColorCreateCopy([uiColor CGColor]));
}

@end

#pragma mark -- CGPoint To NSDictionary

@implementation SACGPointToNSDictionaryValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(CGPointValue)]) {
        CGPoint point = [value CGPointValue];
        point.x = isnormal(point.x) ? point.x : 0.0f;
        point.y = isnormal(point.y) ? point.y : 0.0f;
        return CFBridgingRelease(CGPointCreateDictionaryRepresentation(point));
    }
    
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    CGPoint point = CGPointZero;
    if ([value isKindOfClass:[NSDictionary class]] && CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)value, &point)) {
        return [NSValue valueWithCGPoint:point];
    }
    
    return [NSValue valueWithCGPoint:CGPointZero];
}

@end

#pragma mark -- CGRect To NSDictionary

@implementation SACGRectToNSDictionaryValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(CGRectValue)]) {
        CGRect rect = [value CGRectValue];
        rect.origin.x = isnormal(rect.origin.x) ? rect.origin.x : 0.0f;
        rect.origin.y = isnormal(rect.origin.y) ? rect.origin.y : 0.0f;
        rect.size.width = isnormal(rect.size.width) ? rect.size.width : 0.0f;
        rect.size.height = isnormal(rect.size.height) ? rect.size.height : 0.0f;
        return CFBridgingRelease(CGRectCreateDictionaryRepresentation(rect));
    }
    
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    CGRect rect = CGRectZero;
    if ([value isKindOfClass:[NSDictionary class]] && CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)value, &rect)) {
        return [NSValue valueWithCGRect:rect];
    }
    
    return [NSValue valueWithCGRect:CGRectZero];
}

@end

#pragma mark -- CGSize To NSDictionary

@implementation SACGSizeToNSDictionaryValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value respondsToSelector:@selector(CGSizeValue)]) {
        CGSize size = [value CGSizeValue];
        size.width = isnormal(size.width) ? size.width : 0.0f;
        size.height = isnormal(size.height) ? size.height : 0.0f;
        return CFBridgingRelease(CGSizeCreateDictionaryRepresentation(size));
    }
    
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    CGSize size = CGSizeZero;
    if ([value isKindOfClass:[NSDictionary class]] && CGSizeMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)value, &size)) {
        return [NSValue valueWithCGSize:size];
    }
    
    return [NSValue valueWithCGSize:CGSizeZero];
}

@end

#pragma mark -- NSAttributedString To NSDictionary

@implementation SANSAttributedStringToNSDictionaryValueTransformer

+ (Class)transformedValueClass {
    return [NSDictionary class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSAttributedString class]]) {
        NSAttributedString *attributedString = value;
        
        NSError *error = nil;
        NSData *data = nil;
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
        if ([attributedString respondsToSelector:@selector(dataFromRange:documentAttributes:error:)]) {
            data = [attributedString dataFromRange:NSMakeRange(0, [attributedString length])
                                documentAttributes:@{ NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType}
                                             error:&error];
        }
#endif
        if (data) {
            return @{
                     @"mime_type" : @"text/html",
                     @"data" : [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
                     };
        } else {
            SAError(@"Failed to convert NSAttributedString to HTML: %@", error);
        }
    }
    
    return nil;
}

- (id)reverseTransformedValue:(id)value {
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionaryValue = value;
        NSString *mimeType = dictionaryValue[@"mime_type"];
        NSString *dataString = dictionaryValue[@"data"];
        
        if ([mimeType isEqualToString:@"text/html"] && dataString) {
            NSError *error = nil;
            NSAttributedString *attributedString;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
            NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
            attributedString = [[NSAttributedString alloc] initWithData:data
                                                                options:@{ NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType}
                                                     documentAttributes:NULL
                                                                  error:&error];
#endif
            if (attributedString == nil) {
                SAError(@"Failed to convert HTML to NSAttributed string: %@", error);
            }
            
            return attributedString;
        }
    }
    
    return nil;
}

@end

#pragma mark -- NSNumberToCGFloat

@implementation SANSNumberToCGFloatValueTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *) value;
        
        // if the number is not a cgfloat, cast it to a cgfloat
        if (strcmp([number objCType], (char *) @encode(CGFloat)) != 0) {
            if (strcmp((char *) @encode(CGFloat), (char *) @encode(double)) == 0) {
                value = @([number doubleValue]);
            } else {
                value = @([number floatValue]);
            }
        }
        
        return value;
    }
    
    return nil;
}

@end




