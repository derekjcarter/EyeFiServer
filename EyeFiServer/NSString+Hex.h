//
//  NSString+Hex.h
//
//  Created by Derek Carter.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

@interface NSString (hex)

- (NSString *)hex;
+ (NSString *)strFromHex:(NSString *)str;
+ (NSString *)strToHex:(NSString *)str;

@end