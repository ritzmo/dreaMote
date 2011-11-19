//
//  EPGRefreshSettings.m
//  dreaMote
//
//  Created by Moritz Venn on 15.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "EPGRefreshSettings.h"

@implementation EPGRefreshSettings

@synthesize enabled, begin, end, interval, delay_standby, lastscan, inherit_autotimer, interval_in_seconds, afterevent, force, wakeup, parse_autotimer, adapter, canDoBackgroundRefresh, hasAutoTimer;

- (id)init
{
	if((self = [super init]))
	{
		lastscan = -1;
	}
	return self;
}

@end
