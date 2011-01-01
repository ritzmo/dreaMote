//
//  SignalXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 08.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "SignalXMLReader.h"

#import "../../Objects/Generic/Signal.h"

#import "CXMLElement.h"

@implementation Enigma2SignalXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<SignalSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_delegate release];
	[super dealloc];
}

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
	CXMLNode *currentChild = nil;
	const NSArray *resultNodes = [_parser nodesForXPath:@"/e2frontendstatus" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		GenericSignal *newSignal = [[GenericSignal alloc] init];
		
		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			const NSString *elementName = [currentChild name];			
			if ([elementName isEqualToString:@"e2snrdb"]) {
				const NSString *str = [[currentChild stringValue] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
				newSignal.snrdb = [[str substringToIndex: [str length] - 3] floatValue];
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

		[_delegate performSelectorOnMainThread: @selector(addSignal:)
									withObject: newSignal
								 waitUntilDone: NO];
		[newSignal release];
		
		// Signal is unique
		break;
	}
}

@end
