//
//  EyeFiParser.m
//  EyeFi Gallery
//
//  Created by Derek Carter on 2/18/14.
//  Copyright (c) 2014 Derek Carter. All rights reserved.
//

#import "EyeFiParser.h"

@implementation EyeFiParser
{
    BOOL _isReceivingData;  // Boolean used to trap if we are currently interpreting data
}

- (id)initWithData:(NSData *)data
{
    NSLog(@"EyeFiParser | initWithData");
    
    self = [super init];
    if (self) {
        // Set incoming data
        _data = [data copy];
        _call = [[NSMutableString alloc] init];
        _bodyData = [[NSMutableDictionary alloc] init];
        _parsedString = [[NSMutableString alloc] init];
    }
    
    // Start the parsing of the XML data
    [self startXMLParser];
    return self;
}

- (void)startXMLParser
{
    NSLog(@"EyeFiParser | startXMLParser");
    
    // Set the parser with the initialized data
    NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:self.data];
    [xmlParser setDelegate:self];
    [xmlParser parse];
}



#pragma mark - NSXMLParserDelegate Methods
/***************************************************************************************************************
 * NSXMLParserDelegate Methods
 ***************************************************************************************************************/
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    NSLog(@"EyeFiParser | didStartElement | elementName: %@  namespaceURI: %@  qName: %@", elementName, namespaceURI, qName);
    
    // Return only if this is a response from EyeFi
    if ([[elementName substringToIndex:4] isEqualToString:@"ns1:"]) {
        // Set the call based off elementName that includes "ns1"
        [self.call setString: [elementName componentsSeparatedByString:@":"][1]];
        
        return;
    }
    
    // Return only if specific element names were passed in
    if ([elementName isEqualToString:@"credential"] ||
        [elementName isEqualToString:@"cnonce"] ||
        [elementName isEqualToString:@"filename"] ||
        [elementName isEqualToString:@"filesize"] ||
        [elementName isEqualToString:@"macaddress"] ||
        [elementName isEqualToString:@"transfermode"] ||
        [elementName isEqualToString:@"transfermodetimestamp"]) {
        
        // Set boolean that we've begun receiving data from an EyeFi card
        _isReceivingData = YES;
        
        // Empty the previous parsed string
        [self.parsedString setString:@""];

        return;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    NSLog(@"EyeFiParser | foundCharacters | string: %@", string);
    
    // Continue if we are currently receiving data
    if (_isReceivingData) {
        
        // Appended the string from this call to the parsed string
        [_parsedString appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    NSLog(@"EyeFiParser | didEndElement | elementName: %@  namespaceURI: %@  qName: %@", elementName, namespaceURI, qName);
    
    // Continue if we are currently receiving data
    if (_isReceivingData) {
        
        // Set the current body data dictionary with the retreived parsed string for the XML element name
        [_bodyData setObject:[NSString stringWithFormat:@"%@", self.parsedString] forKey:elementName];
    }
    
    // Set boolean that we've stopped receiving data from an EyeFi card
    _isReceivingData = NO;
}



@end
