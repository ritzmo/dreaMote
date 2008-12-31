//
//  VolumeXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VolumeXMLReader.h"

#import "Volume.h"

@implementation VolumeXMLReader

+ (VolumeXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	VolumeXMLReader *xmlReader = [[VolumeXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)dealloc
{
	[super dealloc];
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
- (void)parseAllEnigma2
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedVolumesCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/e2volume" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedVolumesCounter > 1)
			break;
		
		// A timer in the xml represents a timer, so create an instance of it.
		Volume *newVolume = [[Volume alloc] init];
		
		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];			
			if ([elementName isEqualToString:@"e2result"]) {
				newVolume.result = [[currentChild stringValue] boolValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2resulttext"]) {
				newVolume.resulttext = [currentChild stringValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2current"]) {
				newVolume.current = [[currentChild stringValue] integerValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2ismuted"]) {
				newVolume.ismuted = [[currentChild stringValue] boolValue];
				continue;
			}
		}
		[self.target performSelectorOnMainThread: self.addObject withObject: newVolume waitUntilDone: NO];
		[newVolume release];
	}
}

- (void)parseAllEnigma1
{
}

- (void)parseAllNeutrino
{
}

@end
