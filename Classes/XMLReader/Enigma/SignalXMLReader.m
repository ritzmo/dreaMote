//
//  SignalXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 15.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "SignalXMLReader.h"

#import "../../Objects/Generic/Signal.h"

#import "CXMLElement.h"

@implementation EnigmaSignalXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<SignalSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
	}
	return self;
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8" ?>
 <?xml-stylesheet type="text/xsl" href="/xml/streaminfo.xsl"?>
 <streaminfo>
 <frontend>#FRONTEND#</frontend>
 <service>
 <name>n/a</name>
 <reference></reference>
 </service>
 <provider>n/a</provider>
 <vpid>ffffffffh (-1d)</vpid>
 <apid>ffffffffh (-1d)</apid>
 
 <pcrpid>ffffffffh (-1d)</pcrpid>
 <tpid>ffffffffh (-1d)</tpid>
 <tsid>0000h</tsid>
 <onid>0000h</onid>
 <sid>0000h</sid>
 <pmt>ffffffffh</pmt>
 <video_format>n/a</video_format>
 <namespace>0000h</namespace>
 <supported_crypt_systems>4a70h Dream Multimedia TV (DreamCrypt)</supported_crypt_systems>
 
 <used_crypt_systems>None</used_crypt_systems>
 <satellite>n/a</satellite>
 <frequency>n/a</frequency>
 <symbol_rate>n/a</symbol_rate>
 <polarisation>n/a</polarisation>
 <inversion>n/a</inversion>
 <fec>n/a</fec>
 <snr>n/a</snr>
 <agc>n/a</agc>
 
 <ber>n/a</ber>
 <lock>n/a</lock>
 <sync>n/a</sync>
 <modulation>#MODULATION#</modulation>
 <bandwidth>#BANDWIDTH#</bandwidth>
 <constellation>#CONSTELLATION#</constellation>
 <guardinterval>#GUARDINTERVAL#</guardinterval>
 <transmission>#TRANSMISSION#</transmission>
 <coderatelp>#CODERATELP#</coderatelp>
 
 <coderatehp>#CODERATEHP#</coderatehp>
 <hierarchyinfo>#HIERARCHYINFO#</hierarchyinfo>
 </streaminfo>
 
*/
- (void)parseFull
{
	CXMLNode *currentChild = nil;
	const NSArray *resultNodes = [_parser nodesForXPath:@"/streaminfo" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		GenericSignal *newSignal = [[GenericSignal alloc] init];
		newSignal.snrdb = -1; // enigma does not support this...

		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			const NSString *elementName = [currentChild name];
			if ([elementName isEqualToString:@"snr"]) {
				const NSString *str = [currentChild stringValue];
				newSignal.snr = [[str substringToIndex: [str length] - 1] integerValue];
				continue;
			}
			else if ([elementName isEqualToString:@"ber"]) {
				newSignal.ber = [[currentChild stringValue] integerValue];
				continue;
			}
			else if ([elementName isEqualToString:@"agc"]) {
				NSString *str = [currentChild stringValue];
				newSignal.agc = [[str substringToIndex: [str length] - 1] integerValue];
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
