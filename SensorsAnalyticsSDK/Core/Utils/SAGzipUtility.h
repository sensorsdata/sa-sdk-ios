// SAGzipUtility.h
// SensorsAnalyticsSDK
//
// Created by 雨晗 on 1/20/16
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

#import <Foundation/Foundation.h>


@interface SAGzipUtility : NSObject {
    
}

/***************************************************************************/
/**
 Uses zlib to compress the given data. Note that gzip headers will be added so
 that the data can be easily decompressed using a tool like WinZip, gunzip, etc.
 
 Note: Special thanks to Robbie Hanson of Deusty Designs for sharing sample code
 showing how deflateInit2() can be used to make zlib generate a compressed file
 with gzip headers:
 
 http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html
 
 @param pUncompressedData memory buffer of bytes to compress
 @return Compressed data as an NSData object
 */
+ (NSData *)gzipData:(NSData *)pUncompressedData;

@end
