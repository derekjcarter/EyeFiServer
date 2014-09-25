//
//  EyeFiParser.h
//  EyeFi Gallery
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EyeFiParser : NSOperation <NSXMLParserDelegate>

@property (copy, readonly) NSData *data;
@property (nonatomic, strong) NSMutableString *call;
@property (nonatomic, strong) NSMutableDictionary *bodyData;
@property (nonatomic) NSMutableString *parsedString;

- (id)initWithData:(NSData *)data;

@end
