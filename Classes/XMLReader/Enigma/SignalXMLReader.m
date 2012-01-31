//
//  SignalXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 15.06.09.
//  Copyright 2009-2012 Moritz Venn. All rights reserved.
//

#import "SignalXMLReader.h"

#import <Objects/Generic/Signal.h>

static const char *kEnigmaSignal = "streaminfo";
static const NSUInteger kEnigmaSignalLength = 11;
static const char *kEnigmaSnr = "snr";
static const NSUInteger kEnigmaSnrLength = 4;
static const char *kEnigmaBer = "ber";
static const NSUInteger kEnigmaBerLength = 4;
static const char *kEnigmaAgc = "agc";
static const NSUInteger kEnigmaAgcLength = 4;

@interface EnigmaSignalXMLReader()
@property (nonatomic, strong) GenericSignal *signal;
@end

@implementation EnigmaSignalXMLReader

@synthesize signal;

/* initialize */
- (id)initWithDelegate:(NSObject<SignalSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
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
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigmaSignal, kEnigmaSignalLength))
	{
		signal = [[GenericSignal alloc] init];
		signal.snrdb = NSNotFound; // enigma does not support this...
	}
	else if(	!strncmp((const char *)localname, kEnigmaSnr, kEnigmaSnrLength)
			||	!strncmp((const char *)localname, kEnigmaBer, kEnigmaBerLength)
			||	!strncmp((const char *)localname, kEnigmaAgc, kEnigmaAgcLength)
			)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigmaSignal, kEnigmaSignalLength))
	{
		[_delegate performSelectorOnMainThread:@selector(addSignal:)
									withObject:signal
								 waitUntilDone:NO];
	}
	else if(!strncmp((const char *)localname, kEnigmaSnr, kEnigmaSnrLength))
	{
		NSString *str = [currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		signal.snr = [[str substringToIndex: [str length] - 1] integerValue];
	}
	else if(!strncmp((const char *)localname, kEnigmaBer, kEnigmaBerLength))
	{
		signal.ber = [[currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] integerValue];
	}
	else if(!strncmp((const char *)localname, kEnigmaAgc, kEnigmaAgcLength))
	{
		NSString *str = [currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		signal.agc = [[str substringToIndex: [str length] - 1] integerValue];
	}

	self.currentString = nil;
}

@end
