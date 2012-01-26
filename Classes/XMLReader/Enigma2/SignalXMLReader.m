//
//  SignalXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 08.06.09.
//  Copyright 2009-2012 Moritz Venn. All rights reserved.
//

#import "SignalXMLReader.h"

#import <Objects/Generic/Signal.h>

static const char *kEnigma2Signal = "e2frontendstatus";
static const NSUInteger kEnigma2SignalLength = 17;
static const char *kEnigma2Snrdb = "e2snrdb";
static const NSUInteger kEnigma2SnrdbLength = 8;
static const char *kEnigma2Snr = "e2snr";
static const NSUInteger kEnigma2SnrLength = 6;
static const char *kEnigma2Ber = "e2ber";
static const NSUInteger kEnigma2BerLength = 6;
static const char *kEnigma2Agc = "e2acg";
static const NSUInteger kEnigma2AgcLength = 6;

@interface Enigma2SignalXMLReader()
@property (nonatomic, strong) GenericSignal *signal;
@end

@implementation Enigma2SignalXMLReader

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
 <?xml version="1.0" encoding="UTF-8"?>
 <e2frontendstatus>	
	<e2snrdb>8.31 dB</e2snrdb>
	<e2snr>55 %</e2snr>
	<e2ber>3</e2ber>
	<e2acg>85 %</e2acg>
 </e2frontendstatus>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2Signal, kEnigma2SignalLength))
	{
		signal = [[GenericSignal alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2Snrdb, kEnigma2SnrdbLength)
			||	!strncmp((const char *)localname, kEnigma2Snr, kEnigma2SnrLength)
			||	!strncmp((const char *)localname, kEnigma2Ber, kEnigma2BerLength)
			||	!strncmp((const char *)localname, kEnigma2Agc, kEnigma2AgcLength)
			)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2Signal, kEnigma2SignalLength))
	{
		[_delegate performSelectorOnMainThread:@selector(addSignal:)
									withObject:signal
								 waitUntilDone:NO];
	}
	else if(!strncmp((const char *)localname, kEnigma2Snrdb, kEnigma2SnrdbLength))
	{
		const NSString *str = [currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		signal.snrdb = [[str substringToIndex:[str length] - 3] floatValue];
	}
	else if(!strncmp((const char *)localname, kEnigma2Snr, kEnigma2SnrLength))
	{
		NSString *str = [currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		signal.snr = [[str substringToIndex: [str length] - 2] integerValue];
	}
	else if(!strncmp((const char *)localname, kEnigma2Ber, kEnigma2BerLength))
	{
		signal.ber = [[currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] integerValue];
	}
	else if(!strncmp((const char *)localname, kEnigma2Agc, kEnigma2AgcLength))
	{
		NSString *str = [currentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		signal.agc = [[str substringToIndex: [str length] - 2] integerValue];
	}

	self.currentString = nil;
}

@end
