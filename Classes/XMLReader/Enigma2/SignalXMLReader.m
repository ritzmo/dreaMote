//
//  SignalXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 08.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SignalXMLReader.h"

#import "../../Objects/Generic/Signal.h"

#import "CXMLElement.h"

@implementation Enigma2SignalXMLReader

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <e2frontendstatus>	
	<e2snrdb>8.31 dB</e2snrdb>
	<e2snr>55 %</e2snr>
	<e2ber>3</e2ber>
	<e2acg>85 %</e2acg>
 </e2frontendstatus>
*/
- (void)parseFull
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedSignalCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/e2frontendstatus" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedSignalCounter > 1)
			break;
		
		Signal *newSignal = [[Signal alloc] init];
		
		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];			
			if ([elementName isEqualToString:@"e2snrdb"]) {
				NSString *str = [[currentChild stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				newSignal.snrdb = [[str substringToIndex: [str length] - 3] doubleValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2snr"]) {
				NSString *str = [[currentChild stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				newSignal.snr = [[str substringToIndex: [str length] - 2] integerValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2ber"]) {
				newSignal.ber = [[[currentChild stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] integerValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2acg"]) {
				NSString *str = [[currentChild stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				newSignal.agc = [[str substringToIndex: [str length] - 2] integerValue];
				continue;
			}
		}

		[_target performSelectorOnMainThread: _addObject withObject: newSignal waitUntilDone: NO];
		[newSignal release];
	}
}

@end
