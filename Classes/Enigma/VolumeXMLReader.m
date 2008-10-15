//
//  VolumeXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VolumeXMLReader.h"

static NSUInteger parsedVolumesCounter;

@implementation VolumeXMLReader

@synthesize currentVolumeObject = _currentVolumeObject;

+ (VolumeXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	VolumeXMLReader *xmlReader = [[VolumeXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	parsedVolumesCounter = 0;
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <e2volume>
 <e2result>True</e2result>
 <e2resulttext>state</e2resulttext>
 <e2current>5</e2current>
 <e2ismuted>False</e2ismuted>	
 </e2volume>
*/
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName) {
		elementName = qName;
	}

	// We assume a unique Volume
	if (parsedVolumesCounter > 1) {
		self.currentVolumeObject = nil;

		[parser abortParsing];
	}

	if ([elementName isEqualToString:@"e2volume"]) {

		parsedVolumesCounter++;

		self.currentVolumeObject = [[Volume alloc] init];

		return;
	}

	if (
		[elementName isEqualToString:@"e2result"]
		|| [elementName isEqualToString:@"e2resulttext"]
		|| [elementName isEqualToString:@"e2current"]
		|| [elementName isEqualToString:@"e2ismuted"]

		) {
		// Create a mutable string to hold the contents of this element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else {
		// The element isn't one that we care about, so set the property that holds the 
		// character content of the current element to nil. That way, in the parser:foundCharacters:
		// callback, the string that the parser reports will be ignored.
		self.contentOfCurrentProperty = nil;
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{	 
	if (qName) {
		elementName = qName;
	}

	if ([elementName isEqualToString:@"e2result"]) {
		self.currentVolumeObject.result = [self.contentOfCurrentProperty boolValue];
	} else if ([elementName isEqualToString:@"e2resulttext"]) {
		self.currentVolumeObject.resulttext = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2current"]) {
		self.currentVolumeObject.current = [self.contentOfCurrentProperty integerValue];
	} else if ([elementName isEqualToString:@"e2ismuted"]) {
		self.currentVolumeObject.ismuted = [self.contentOfCurrentProperty boolValue];
	} else if ([elementName isEqualToString:@"e2volume"]) {
		[self.target performSelectorOnMainThread: self.addObject withObject: self.currentVolumeObject waitUntilDone: NO];
	}
	self.contentOfCurrentProperty = nil;
}

@end
