//  NSInvocation+SAHelpers.m
//  SensorsAnalyticsSDK
//
//  Created by 雨晗 on 1/20/16
//  Copyright © 2015-2020 Sensors Data Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import <objc/runtime.h>
#import "SALogger.h"
#import "NSInvocation+SAHelpers.h"

typedef union {
    char                    _chr;
    unsigned char           _uchr;
    short                   _sht;
    unsigned short          _usht;
    int                     _int;
    unsigned int            _uint;
    long                    _lng;
    unsigned long           _ulng;
    long long               _lng_lng;
    unsigned long long      _ulng_lng;
    float                   _flt;
    double                  _dbl;
    _Bool                   _bool;
} MPObjCNumericTypes;

static void SAFree(void *p) {
    if (p) {
        free(p);
    }
}

static void *SAAllocBufferForObjCType(const char *objCType) {
    void *buffer = NULL;

    NSUInteger size, alignment;
    NSGetSizeAndAlignment(objCType, &size, &alignment);

    int result = posix_memalign(&buffer, MAX(sizeof(void *), alignment), size);
    if (result != 0) {
        SAError(@"Error allocating aligned memory: %s", strerror(result));
    }

    if (buffer) {
        memset(buffer, 0, size);
    }

    return buffer;
}

@implementation NSInvocation (SAHelpers)

- (void)sa_setArgument:(id)argumentValue atIndex:(NSUInteger)index {
    const char *argumentType = [self.methodSignature getArgumentTypeAtIndex:index];
    if ([argumentValue isKindOfClass:[NSNumber class]] && strnlen(argumentType, 8) == 1) {
        // Deal with NSNumber instances (converting to primitive numbers)
        NSNumber *numberArgument = argumentValue;

        MPObjCNumericTypes arg;
        switch (argumentType[0]) {
            case _C_CHR:      arg._chr = [numberArgument charValue];                break;
            case _C_UCHR:     arg._uchr = [numberArgument unsignedCharValue];        break;
            case _C_SHT:      arg._sht = [numberArgument shortValue];               break;
            case _C_USHT:     arg._usht = [numberArgument unsignedShortValue];       break;
            case _C_INT:      arg._int = [numberArgument intValue];                 break;
            case _C_UINT:     arg._uint = [numberArgument unsignedIntValue];         break;
            case _C_LNG:      arg._lng = [numberArgument longValue];                break;
            case _C_ULNG:     arg._ulng = [numberArgument unsignedLongValue];        break;
            case _C_LNG_LNG:  arg._lng_lng = [numberArgument longLongValue];            break;
            case _C_ULNG_LNG: arg._ulng_lng = [numberArgument unsignedLongLongValue];    break;
            case _C_FLT:      arg._flt = [numberArgument floatValue];               break;
            case _C_DBL:      arg._dbl = [numberArgument doubleValue];              break;
            case _C_BOOL:     arg._bool = [numberArgument boolValue];                break;
            default:
                NSAssert(NO, @"Currently unsupported argument type!");
        }

        [self setArgument:&arg atIndex:(NSInteger)index];
    } else if ([argumentValue isKindOfClass:[NSValue class]]) {
        NSValue *valueArgument = argumentValue;

        NSAssert2(strcmp([valueArgument objCType], argumentType) == 0, @"Objective-C type mismatch (%s != %s)!", [valueArgument objCType], argumentType);

        void *buffer = SAAllocBufferForObjCType([valueArgument objCType]);

        [valueArgument getValue:buffer];

        [self setArgument:&buffer atIndex:(NSInteger)index];

        SAFree(buffer);
    } else {
        switch (argumentType[0]) {
            case _C_ID: {
                [self setArgument:&argumentValue atIndex:(NSInteger)index];
                break;
            }
            case _C_SEL: {
                SEL sel = NSSelectorFromString(argumentValue);
                [self setArgument:&sel atIndex:(NSInteger)index];
                break;
            }
            default:
                NSAssert(NO, @"Currently unsupported argument type!");
        }
    }
}

-(void)sa_setArgumentsFromArray: (NSArray *)argumentArray {
    NSParameterAssert([argumentArray count] == ([self.methodSignature numberOfArguments] - 2));

    for (NSUInteger i = 0; i < [argumentArray count]; ++i) {
        NSUInteger argumentIndex = 2 + i;
        [self sa_setArgument:argumentArray[i] atIndex:argumentIndex];
    }
}

- (id)sa_returnValue {
    __strong id returnValue = nil;

    NSMethodSignature *methodSignature = self.methodSignature;

    const char *objCType = [methodSignature methodReturnType];
    void *buffer = SAAllocBufferForObjCType(objCType);

    [self getReturnValue:buffer];

    if (strnlen(objCType, 8) == 1) {
        switch (objCType[0]) {
            case _C_CHR:      returnValue = @(*((char *)buffer));                   break;
            case _C_UCHR:     returnValue = @(*((unsigned char *)buffer));          break;
            case _C_SHT:      returnValue = @(*((short *)buffer));                  break;
            case _C_USHT:     returnValue = @(*((unsigned short *)buffer));         break;
            case _C_INT:      returnValue = @(*((int *)buffer));                    break;
            case _C_UINT:     returnValue = @(*((unsigned int *)buffer));           break;
            case _C_LNG:      returnValue = @(*((long *)buffer));                   break;
            case _C_ULNG:     returnValue = @(*((unsigned long *)buffer));           break;
            case _C_LNG_LNG:  returnValue = @(*((long long *)buffer));              break;
            case _C_ULNG_LNG: returnValue = @(*((unsigned long long *)buffer));      break;
            case _C_FLT:      returnValue = @(*((float *)buffer));                  break;
            case _C_DBL:      returnValue = @(*((double *)buffer));                 break;
            case _C_BOOL:     returnValue = @(*((_Bool *)buffer));                  break;
            case _C_ID:       returnValue = *((__unsafe_unretained id *)buffer);    break;
            case _C_SEL:      returnValue = NSStringFromSelector(*((SEL *)buffer)); break;
            default:
                NSAssert1(NO, @"Unhandled return type: %s", objCType);
                break;
        }
    } else {
        switch (objCType[0]) {
            case _C_STRUCT_B: returnValue = [NSValue valueWithBytes:buffer objCType:objCType]; break;
            case _C_PTR: {
                CFTypeRef cfTypeRef = *(CFTypeRef *)buffer;
                if ((strcmp(objCType, @encode(CGImageRef)) == 0 && CFGetTypeID(cfTypeRef) == CGImageGetTypeID()) ||
                    (strcmp(objCType, @encode(CGColorRef)) == 0 && CFGetTypeID(cfTypeRef) == CGColorGetTypeID())) {
                    returnValue = (__bridge id)cfTypeRef;
                } else {
                    NSAssert(NO, @"Currently unsupported return type!");
                }
                break;
            }
            default:
                NSAssert1(NO, @"Unhandled return type: %s", objCType);
                break;
        }
    }

    SAFree(buffer);

    return returnValue;
}

@end
