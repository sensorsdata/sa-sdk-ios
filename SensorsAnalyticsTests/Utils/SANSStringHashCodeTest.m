//
// SANSStringHashCodeTest.m
// SensorsAnalyticsTests
//
// Created by wenquan on 2021/10/13.
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

#import <XCTest/XCTest.h>
#import "NSString+SAHashCode.h"

@interface SANSStringHashCodeTest : XCTestCase

@end

@implementation SANSStringHashCodeTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testHashCodeWithEmptyString {
    NSString *str = @"";
    XCTAssertEqual([str sensorsdata_hashCode], 0);
}

- (void)testHashCodeWithNilString {
    NSString *str = nil;
    XCTAssertEqual([str sensorsdata_hashCode], 0);
}

- (void)testHashCodeWithEqualEnglishString {
    XCTAssertEqual([@"Hello" sensorsdata_hashCode], [@"Hello" sensorsdata_hashCode]);
}

- (void)testHashCodeWithNotEqualEnglishString {
    XCTAssertNotEqual([@"Hello" sensorsdata_hashCode], [@"llo" sensorsdata_hashCode]);
}

- (void)testHashCodeWithEqualChineseString {
    XCTAssertEqual([@"Hello你好" sensorsdata_hashCode], [@"Hello你好" sensorsdata_hashCode]);
}

- (void)testHashCodeWithNotEqualChineseString {
    XCTAssertNotEqual([@"Hello你好" sensorsdata_hashCode], [@"Hello好" sensorsdata_hashCode]);
}

- (void)testHashCodeWithEqualEmojiString {
    XCTAssertEqual([@"🔥sd🙂哈哈😆" sensorsdata_hashCode], [@"🔥sd🙂哈哈😆" sensorsdata_hashCode]);
}

- (void)testHashCodeWithNotEqualEmojiString {
    XCTAssertNotEqual([@"🔥sd🙂哈哈😆" sensorsdata_hashCode], [@"🔥sd🙂" sensorsdata_hashCode]);
}

- (void)testHashCodeWithEqualSpecialString {
    XCTAssertEqual([@"^*&()%^)$*#!@#!#@" sensorsdata_hashCode], [@"^*&()%^)$*#!@#!#@" sensorsdata_hashCode]);
}

- (void)testHashCodeWithNotEqualSpecialString {
    XCTAssertNotEqual([@"^*&()%^)$*#!@#!#@" sensorsdata_hashCode], [@"^*&()%^)$*#!@#!" sensorsdata_hashCode]);
}

/// 测试新旧 hachCode 结果差异
- (void)testNewHashCodeResults {
    NSMutableDictionary *differentRresults = [NSMutableDictionary dictionary];
    for (NSInteger index = 0; index < 100; index ++) {
        // 生成随机字符串
        NSInteger randomLength = arc4random_uniform(100);
        NSString *randomString = [self randomStringWithLength:randomLength];

        if([randomString sensorsdata_hashCode] != [self historicalHashCodeWithString:randomString]) {
            differentRresults[randomString] = @[@([randomString sensorsdata_hashCode]), @([self historicalHashCodeWithString:randomString])];
        }
    }

    //比较两种
    XCTAssertTrue(differentRresults.count == 0);

}

// 已经参考 Java 代码，重新实现 hashCode
/* java hashCode 实现
 public int hashCode() {
         int h = hash;
         // BEGIN Android-changed: Implement in terms of charAt().
         final int len = length();
         if (h == 0 && len > 0) {
             for (int i = 0; i < len; i++) {
                 h = 31 * h + charAt(i);
             }
             hash = h;
         // END Android-changed: Implement in terms of charAt().
         }
         return h;
     }
 */
/// iOS SDK 历史版本 hashCode 实现
- (int)historicalHashCodeWithString:(NSString *)jsonString {
    int hash = 0;
    for (int i = 0; i<[jsonString length]; i++) {
        NSString *s = [jsonString substringWithRange:NSMakeRange(i, 1)];
        char *unicode = (char *)[s cStringUsingEncoding:NSUnicodeStringEncoding];
        int charactorUnicode = 0;

        size_t length = strnlen(unicode, 4);
        for (int n = 0; n < length; n ++) {
            charactorUnicode += (int)((unicode[n] & 0xff) << (n * sizeof(char) * 8));
        }
        hash = hash * 31 + charactorUnicode;
    }
    return hash;
}

/// 构建随机字符串，包含 UTF8 字符集
- (NSString *)randomStringWithLength:(NSInteger)length {

    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#$%&()*+,-./:;<=>?@[]^_{}|~汉字😊kl😆da🔥，。/;'[]=- `~!#$%^&*()_+|}{\":?><";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform((uint32_t)[letters length])]];
    }
    NSData *randomData = [randomString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *resultString = [[NSString alloc] initWithData:randomData encoding:NSUTF8StringEncoding];
    return resultString;
}

/* 使用随机的 utf8 字符串测试，存在部分 hashCode，新老方式结果不同
 备注：新方式为参考 Java 重新实现的算法；老方式为 iOS 历史代码
 针对 hashCode 结果不同的字符，使用 Java 测试，Java 的 hashCode() 结果，和新方案一致
 即新方案，兼容更多字符集，且 hashCode 结果和 Java 一致
 */
- (NSString *)randomUTF8StringWithLength:(NSInteger)length {
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];

     for (int i = 0; i < length; i++) {
         // 随机选择一个 Unicode 字符范围内的字符
         unichar randomUnicodeChar = (unichar)(arc4random_uniform(0xFFFF + 1));

         // 转换为 UTF-8 编码
         NSString *utf8Character = [NSString stringWithFormat:@"%C", randomUnicodeChar];
         NSData *utf8Data = [utf8Character dataUsingEncoding:NSUTF8StringEncoding];

         if (utf8Data) {
             [randomString appendString:utf8Character];
         }
     }

     return randomString;
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
