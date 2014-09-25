//
//  EyeFiConnection.m
//  EyeFi Gallery
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//  https://code.google.com/p/sceye-fi/wiki/UploadProtocol
//

#import "EyeFiConnection.h"
#import "EyeFiServer.h"
#import "EyeFiParser.h"
#import "NSString+Hex.h"
#import "NSData+MD5.h"
#import "NSFileManager+EyeFi.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "HTTPDynamicFileResponse.h"
#import "MultipartFormDataParser.h"
#import "MultipartMessageHeaderField.h"

@implementation EyeFiConnection

- (id)initWithData:(NSData *)data
{
    NSLog(@"EyeFiConnection | initWithData");
    
    self = [super init];
    if (self) {
        self.parser = [MultipartFormDataParser alloc];
    }
    return self;
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    return YES;
}



#pragma mark - Prepare Data Methods
/***************************************************************************************************************
 * Prepare Data Methods
 ***************************************************************************************************************/
- (void)prepareForBodyWithSize:(UInt64)contentLength
{
    NSLog(@"EyeFiConnection | prepareForBodyWithSize");
    
    NSString* boundary = [request headerField:@"boundary"];
    self.parser = [[MultipartFormDataParser alloc] initWithBoundary:boundary formEncoding:NSUTF8StringEncoding];
    self.parser.delegate = self;
}



#pragma mark - Process Data Methods
/***************************************************************************************************************
 * Process Data Methods
 ***************************************************************************************************************/
- (void)processBodyData:(NSData *)postDataChunk
{
    NSLog(@"EyeFiConnection | processBodyData");
    
    [self.parser appendData:postDataChunk];
    _postData = postDataChunk;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    NSLog(@"EyeFiConnection | httpResponseForMethod | method: %@  path: %@", method, path);
    
    if ([path isEqualToString:@"/api/soap/eyefilm/v1/upload"]) {
        // Need to verify the photo was transferred successfully.
        // Currently just returns "success" after a photo is uploaded.
        return [[HTTPDataResponse alloc] initWithData:[[self stringForCall:@"UploadPhotoResponse"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    self.parseQueue = [NSOperationQueue new];
    EyeFiParser *parseOperation = [[EyeFiParser alloc] initWithData:self.postData];
    [self.parseQueue addOperation:parseOperation];
    [self.parseQueue waitUntilAllOperationsAreFinished];
    
    NSLog(@"EyeFiConnection | httpResponseForMethod | Method: %@", parseOperation.call);
    
    if ([parseOperation.call isEqualToString:@"StartSession"]) {
        NSString *credential = [self generateEyeFiCredential:[parseOperation.bodyData objectForKey:@"macaddress"] cnonce:[parseOperation.bodyData objectForKey:@"cnonce"]];
        NSLog(@"EyeFiConnection | httpResponseForMethod | credential: %@", credential);
        
        NSString* result = [NSString stringWithFormat:
                            [self stringForCall:@"StartSessionResponse"],
                            credential,
                            [self generateRandomToken],
//                            @"33282",
                            [parseOperation.bodyData objectForKey:@"transfermode"],
                            [parseOperation.bodyData objectForKey:@"transfermodetimestamp"],
                            @"true"];
        
        NSLog(@"EyeFiConnection | httpResponseForMethod | result: %@", result);
        
        /* Transfer modes:
          33282 = nef and jpg
          32770 = jpg only
        */
        
        return [[HTTPDataResponse alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    if ([parseOperation.call isEqualToString:@"GetPhotoStatus"]) {
        
        // Notify the application a photo is incoming
        [[NSNotificationCenter defaultCenter] postNotificationName:EyeFiNotificationIncomingPhoto object:nil userInfo:[NSDictionary dictionaryWithObject:parseOperation.bodyData[@"filename"] forKey:@"path"]];
        
        return [[HTTPDataResponse alloc] initWithData:[[self stringForCall:@"GetPhotoStatusResponse"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    // The "MarkLastPhotoInRoll" is not required for functionality.
    // Will add it later, skipping now due to time constraints.
    
    return [super httpResponseForMethod:method URI:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    NSLog(@"EyeFiConnection | expectsRequestBodyFromMethod : method=%@  path=%@", method, path);
    
    // Inform HTTP server that we expect a body to accompany a POST request
	if([method isEqualToString:@"POST"] && [path isEqualToString:@"/api/soap/eyefilm/v1/upload"]) {
        // here we need to make sure, boundary is set in header
        NSString* contentType = [request headerField:@"Content-Type"];
        //NSLog(@"contentType: %@", contentType);
        NSUInteger paramsSeparator = [contentType rangeOfString:@";"].location;
        if( NSNotFound == paramsSeparator ) {
            //NSLog(@"paramsSeparator NSNotFound");
            return NO;
        }
        if( paramsSeparator >= contentType.length - 1 ) {
            //NSLog(@"paramsSeparator >= contentType.length: %i", contentType.length);
            return NO;
        }
        NSString* type = [contentType substringToIndex:paramsSeparator];
        //NSLog(@"type: %@", type);
        if( ![type isEqualToString:@"multipart/form-data"] ) {
            // we expect multipart/form-data content type
            return NO;
        }
        
		// enumerate all params in content-type, and find boundary there
        NSArray* params = [[contentType substringFromIndex:paramsSeparator + 1] componentsSeparatedByString:@";"];
        for( NSString* param in params ) {
            paramsSeparator = [param rangeOfString:@"="].location;
            if( (NSNotFound == paramsSeparator) || paramsSeparator >= param.length - 1 ) {
                continue;
            }
            NSString* paramName = [param substringWithRange:NSMakeRange(1, paramsSeparator-1)];
            NSString* paramValue = [param substringFromIndex:paramsSeparator+1];
            
            if( [paramName isEqualToString: @"boundary"] ) {
                // let's separate the boundary from content-type, to make it more handy to handle
                [request setHeaderField:@"boundary" value:paramValue];
            }
        }
        // check if boundary specified
        if( nil == [request headerField:@"boundary"] )  {
            return NO;
        }
        return YES;
    }
	return [super expectsRequestBodyFromMethod:method atPath:path];
}

- (void)processStartOfPartWithHeader:(MultipartMessageHeader*)header
{
    NSLog(@"EyeFiConnection | processStartOfPartWithHeader");
    
    MultipartMessageHeaderField* disposition = [header.fields objectForKey:@"Content-Disposition"];
	NSString* filename = [[disposition.params objectForKey:@"filename"] lastPathComponent];
    if ( (nil == filename) || [filename isEqualToString: @""] ) {
		return;
	}
    
    NSString* uploadDirPath = [@"~/Documents" stringByExpandingTildeInPath];
    
    NSTimeInterval timeInMiliseconds = [[NSDate date] timeIntervalSince1970];
    NSString *filePrefix = [filename componentsSeparatedByString:@"."][0];
    NSString *fileExtensions = [filename stringByReplacingOccurrencesOfString:filePrefix withString:@""];
    _filename = [NSString stringWithFormat:@"%f%@", timeInMiliseconds, fileExtensions];
	
    _imagePath = [uploadDirPath stringByAppendingPathComponent: filename];
    if( [[NSFileManager defaultManager] fileExistsAtPath:_imagePath] ) {
        self.storeFile = nil;
    }
    else {
		if(![[NSFileManager defaultManager] createFileAtPath:_imagePath contents:nil attributes:nil]) {
			NSLog(@"Could not create file at path: %@", _imagePath);
		}
		self.storeFile = [NSFileHandle fileHandleForWritingAtPath:_imagePath];
    }
}

- (void)processContent:(NSData*)data WithHeader:(MultipartMessageHeader*)header
{
	NSLog(@"EyeFiConnection | processContent");
    
    if (self.storeFile) {
		[self.storeFile writeData:data];
	}
}

- (void)processEndOfPartWithHeader:(MultipartMessageHeader*)header
{
	NSLog(@"EyeFiConnection | processEndOfPartWithHeader");
    
    if (self.storeFile) {
        [self.storeFile closeFile];
        self.storeFile = nil;
        
        [[NSFileManager defaultManager] unarchiveEyeFi:_imagePath andNewFilename:_filename];
    }
}



#pragma mark - String Helper Methods
/***************************************************************************************************************
 * String Helper Methods
 ***************************************************************************************************************/
- (NSString *)stringForCall:(NSString *)call
{
    NSLog(@"EyeFiConnection | stringForCall: %@", call);
    
    // Build string from call xml file
    NSString *returnString = [NSString stringWithFormat:@"%@/%@.xml", [[NSBundle mainBundle] resourcePath], call];
    return [NSString stringWithContentsOfFile:returnString encoding:NSUTF8StringEncoding error:nil];
}

- (NSString *)generateRandomToken
{
    NSLog(@"EyeFiConnection | generateRandomToken");
    
    // Loop over 32 characters and choose a character at random
    NSString *availableChars = @"abcdefghijklmnopqrstuvwxyz0123456789";
    NSMutableString *returnString = [NSMutableString stringWithCapacity: 32];
    for (int i=0; i<32; i++) {
        [returnString appendFormat: @"%C", [availableChars characterAtIndex: arc4random() % [availableChars length]]];
    }
    return returnString;
}

- (NSData *)createDataWithHexString:(NSString *)hexString
{
    NSLog(@"EyeFiConnection | createDataWithHexString: %@", hexString);
    
    NSUInteger hexStringLength = [hexString length];
    unichar *inChars = alloca(sizeof(unichar) * hexStringLength);
    [hexString getCharacters:inChars range:NSMakeRange(0, hexStringLength)];
    UInt8 *outBytes = malloc(sizeof(UInt8) * ((hexStringLength / 2) + 1));
    NSInteger i = 0;
    NSInteger o = 0;
    UInt8 outByte = 0;
    for (i = 0; i < hexStringLength; i++) {
        UInt8 c = inChars[i];
        SInt8 value = -1;
        
        if (c >= '0' && c <= '9') {
            value = (c - '0');
        } else if (c >= 'A' && c <= 'F') {
            value = 10 + (c - 'A');
        } else if (c >= 'a' && c <= 'f') {
            value = 10 + (c - 'a');
        }
        
        if (value >= 0) {
            if (i % 2 == 1) {
                outBytes[o++] = (outByte << 4) | value;
                outByte = 0;
            } else {
                outByte = value;
            }
        } else {
            if (o != 0) {
                break;
            }
        }
    }
    
    return [[NSData alloc] initWithBytesNoCopy:outBytes length:o freeWhenDone:YES];
}

- (NSString *)generateEyeFiCredential:(NSString *)macaddress cnonce:(NSString *)cnonce
{
    NSLog(@"EyeFiConnection | generateEyeFiCredential | macaddress: %@  cnonce: %@", macaddress, cnonce);
    
    // Eye-Fi upload key can be found at "~/Library/Eye-Fi/Settings.xml"
    NSString *eyefi_upload_key = ((EyeFiServer *)config.server).uploadKey;
    return [[self createDataWithHexString: [NSString stringWithFormat:@"%@%@%@", macaddress, cnonce, eyefi_upload_key]] MD5];
}



@end
