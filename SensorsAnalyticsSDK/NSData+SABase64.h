//
//  NSData+Base64.h
//  base64
//
//  Created by Matt Gallagher on 2009/06/03.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import <Foundation/Foundation.h>

void *SA_NewBase64Decode(
                         const char *inputBuffer,
                         size_t length,
                         size_t *outputLength);

char *SA_NewBase64Encode(
                         const void *inputBuffer,
                         size_t length,
                         bool separateLines,
                         size_t *outputLength);

@interface NSData (SA_Base64)

+ (NSData *)sa_dataFromBase64String:(NSString *)aString;
- (NSString *)sa_base64EncodedString;

@end
