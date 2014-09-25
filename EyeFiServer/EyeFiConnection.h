//
//  EyeFiConnection.h
//  EyeFi Gallery
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPConnection.h"

@class MultipartFormDataParser;

@interface EyeFiConnection : HTTPConnection

@property (nonatomic, strong) MultipartFormDataParser *parser;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSData *postData;
@property (nonatomic, strong) NSFileHandle *storeFile;
@property (nonatomic) NSOperationQueue *parseQueue;

@end
