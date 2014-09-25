//
//  NSFileManager+EyeFi.h
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (EyeFi)

- (void)unarchiveEyeFi:(NSString *)path andNewFilename:(NSString *)newFilename;

@end
