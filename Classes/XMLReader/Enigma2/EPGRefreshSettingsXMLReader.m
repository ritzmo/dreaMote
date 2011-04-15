//
//  EPGRefreshSettingsXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 15.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "EPGRefreshSettingsXMLReader.h"

#import "Constants.h"

@interface Enigma2EPGRefreshSettingsXMLReader()
@property (nonatomic, retain) EPGRefreshSettings *settings;
@property (nonatomic, retain) NSString *lastSettingName;
@end

@implementation Enigma2EPGRefreshSettingsXMLReader

@synthesize lastSettingName, settings;

/* initialize */
- (id)initWithDelegate:(NSObject<EPGRefreshSettingsSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
		settings = [[EPGRefreshSettings alloc] init];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[lastSettingName release];
	[settings release];

	[super dealloc];
}

/* send fake object */
- (void)sendErroneousObject
{
	// fake settings are stupid, don't send them
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8" ?>
 <e2settings>
 <e2setting>
 <e2settingname>config.plugins.epgrefresh.enabled</e2settingname>
 <e2settingvalue>True</e2settingvalue>
 </e2setting>
 </e2settings>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(	!strncmp((const char *)localname, kEnigma2SettingName, kEnigma2SettingNameLength)
	||	!strncmp((const char *)localname, kEnigma2SettingValue, kEnigma2SettingValueLength)
		)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2SettingName, kEnigma2SettingNameLength))
	{
		self.lastSettingName = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2SettingValue, kEnigma2SettingValueLength))
	{
		if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.enabled"])
		{
			settings.enabled = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.begin"])
		{
			settings.begin = [NSDate dateWithTimeIntervalSince1970:[currentString doubleValue]];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.end"])
		{
			settings.end = [NSDate dateWithTimeIntervalSince1970:[currentString doubleValue]];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.interval"])
		{
			settings.interval = [currentString integerValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.delay_standby"])
		{
			settings.delay_standby = [currentString integerValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.inherit_autotimer"])
		{
			settings.inherit_autotimer = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.afterevent"])
		{
			settings.afterevent = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.force"])
		{
			settings.force = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.wakeup"])
		{
			settings.wakeup = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.parse_autotimer"])
		{
			settings.parse_autotimer = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.background"])
		{
			settings.background = [currentString boolValue];
		}
		self.lastSettingName = nil;
	}
	self.currentString = nil;
}

@end
