//
//  NSFileManager+EyeFi.m
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import "NSFileManager+EyeFi.h"
#import "NSFileManager+Tar.h"
#import "EyeFiServer.h"

@implementation NSFileManager (EyeFi)

- (void)unarchiveEyeFi:(NSString *)path andNewFilename:(NSString *)newFilename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSData* tarData = [NSData dataWithContentsOfFile:path];
    NSError *error;
    NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
    NSString *filename = pathComponents[[pathComponents count]-1];
    
    // Create directory
    [fileManager createFilesAndDirectoriesAtPath:[path stringByReplacingOccurrencesOfString:filename withString:@""] withTarData:tarData error:&error];
    
    // Remove tar file
    [fileManager removeItemAtPath:path error:&error];
    
    // Remove log file
    [fileManager removeItemAtPath:[path stringByReplacingOccurrencesOfString:@".tar" withString:@".log"] error:&error];

    // Move file to new filename
    NSString *newPath = [path stringByReplacingOccurrencesOfString:@".tar" withString:@""];
    newPath = [newPath stringByReplacingOccurrencesOfString:[filename stringByReplacingOccurrencesOfString:@".tar" withString:@""] withString:newFilename];
    newPath = [newPath stringByReplacingOccurrencesOfString:@".tar" withString:@""];
    [fileManager moveItemAtPath:[path stringByReplacingOccurrencesOfString:@".tar" withString:@""] toPath:newPath error:&error];
    
    // Post notification to gallery
    [[NSNotificationCenter defaultCenter] postNotificationName:EyeFiNotificationUnarchiveComplete object:nil userInfo:[NSDictionary dictionaryWithObject:newPath forKey:@"path"]];
}

@end
