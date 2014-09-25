//
//  EyeFiServer.h
//  EyeFi Server
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPServer.h"

static NSString *EyeFiNotificationIncomingPhoto = @"EyeFiIncomingPhoto";
static NSString *EyeFiNotificationCommunication = @"EyeFiCommunication";
static NSString *EyeFiNotificationUnarchiveComplete = @"EyeFiUnarchiveComplete";

@interface EyeFiServer : HTTPServer

@property NSString *uploadKey;

- (id)initWithUploadKey:(NSString *)uploadKey;
- (void)startServer;
- (void)stopServer;

@end
