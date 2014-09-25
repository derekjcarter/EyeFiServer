//
//  EyeFiServer.m
//  EyeFi Server
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import "EyeFiServer.h"
#import "EyeFiConnection.h"

@implementation EyeFiServer

- (id)initWithUploadKey:(NSString *)uploadKey
{
    NSLog(@"EyeFiServer | initWithUploadKey: %@", uploadKey);
    
    self = [super init];
    if (self) {
        // Set upload key
        self.uploadKey = uploadKey;
        
        // Set up httpserver with the Eye-Fi connection class
        [self setConnectionClass: [EyeFiConnection class]];
        [self setType: @"_http._tcp."];
        [self setPort: 59278];
        
        // set documentRoot to Documents folder
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        self.documentRoot = basePath;
    }
    return self;
}

- (void)startServer
{
    [self start: nil];
}

- (void)stopServer
{
    [self stop];
}

@end