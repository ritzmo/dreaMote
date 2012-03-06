//
//  AutoTimerSettings.m
//  dreaMote
//
//  Created by Moritz Venn on 02.12.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerSettings.h"

@implementation AutoTimerSettings

@synthesize addsimilar_on_conflict, autopoll, autotimer_tag, disabled_on_conflict, editor, fastscan, hasVps, interval, maxdays, name_tag, notifconflict, notifsimilar, refresh, show_in_extensionsmenu, try_guessing, version, api_version;

- (id)init
{
	if((self = [super init]))
	{
		version = -1; // default to unknown
		api_version = -1; // default to unknown
	}
	return self;
}

// vps is only fully available with api 1.2 and newer. earlier versions lacked the api to change the settings (so of no use for us).
- (BOOL)hasVps
{
	return hasVps && api_version >= 1.2;
}

@end
