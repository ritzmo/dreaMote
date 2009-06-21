//
//  VolumeXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VolumeXMLReader.h"

#import "../../Objects/Generic/Volume.h"

@implementation Enigma2VolumeXMLReader

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
- (void)parseFull
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedVolumesCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/e2volume" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		// Volume is unique
		if(++parsedVolumesCounter > 1)
			break;
		
		// A timer in the xml represents a timer, so create an instance of it.
		GenericVolume *newVolume = [[GenericVolume alloc] init];
		
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
		[_target performSelectorOnMainThread: _addObject withObject: newVolume waitUntilDone: NO];
		[newVolume release];
	}
}

@end
