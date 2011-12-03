//
//  AutoTimerSettingsXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 02.12.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerSettingsXMLReader.h"

#import "Constants.h"
#import <Objects/Generic/AutoTimerSettings.h>

@interface Enigma2AutoTimerSettingsXMLReader()
@property (nonatomic, strong) AutoTimerSettings *settings;
@property (nonatomic, strong) NSString *lastSettingName;
@end

@implementation Enigma2AutoTimerSettingsXMLReader

@synthesize lastSettingName, settings;

/* initialize */
- (id)initWithDelegate:(NSObject<AutoTimerSettingsSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
		settings = [[AutoTimerSettings alloc] init];
	}
	return self;
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
 <e2settingname>config.plugins.autotimer.autopoll</e2settingname>
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
	if(!strncmp((const char *)localname, kEnigma2Settings, kEnigma2SettingsLength))
	{
		[_delegate performSelectorOnMainThread:@selector(autotimerSettingsRead:) withObject:settings waitUntilDone:NO];
	}
	else if(!strncmp((const char *)localname, kEnigma2SettingName, kEnigma2SettingNameLength))
	{
		self.lastSettingName = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2SettingValue, kEnigma2SettingValueLength))
	{
		if([lastSettingName isEqualToString:@"config.plugins.autotimer.autopoll"])
		{
			settings.autopoll = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.autotimer.interval"])
		{
			settings.interval = [currentString integerValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.autotimer.refresh"])
		{
			if([currentString isEqualToString:@"none"])
				settings.refresh = REFRESH_NONE;
			else if([currentString isEqualToString:@"auto"])
				settings.refresh = REFRESH_AUTO;
			else
				settings.refresh = REFRESH_ALL;
		}
		else if([lastSettingName isEqualToString:@"config.plugins.autotimer.try_guessing"])
		{
			settings.try_guessing = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.autotimer.editor"])
		{
			if([currentString isEqualToString:@"plain"])
				settings.editor = EDITOR_CLASSIC;
			else
				settings.editor = EdiTOR_WIZARD;
		}
		else if([lastSettingName isEqualToString:@"config.plugins.autotimer.addsimilar_on_conflict"])
		{
			settings.addsimilar_on_conflict = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.autotimer.disabled_on_conflict"])
		{
			settings.disabled_on_conflict = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.autotimer.show_in_extensionsmenu"])
		{
			settings.show_in_extensionsmenu = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.autotimer.fastscan"])
		{
			settings.fastscan = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.autotimer.notifconflict"])
		{
			settings.notifconflict = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.notifsimilar"])
		{
			settings.notifsimilar = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"config.plugins.epgrefresh.maxdaysinfuture"])
		{
			settings.maxdays = [currentString integerValue];
		}
		else if([lastSettingName isEqualToString:@"hasVps"])
		{
			settings.hasVps = [currentString boolValue];
		}
		else if([lastSettingName isEqualToString:@"version"])
		{
			NSInteger intValue = [currentString integerValue];
			if(intValue > 0) // only change on valid version
				settings.version = intValue;
		}
		self.lastSettingName = nil;
	}
	self.currentString = nil;
}

@end
