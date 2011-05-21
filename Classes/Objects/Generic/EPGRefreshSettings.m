//
//  EPGRefreshSettings.m
//  dreaMote
//
//  Created by Moritz Venn on 15.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "EPGRefreshSettings.h"

@implementation EPGRefreshSettings

@synthesize enabled, begin, end, interval, delay_standby, inherit_autotimer, afterevent, force, wakeup, parse_autotimer, adapter, canDoBackgroundRefresh, hasAutoTimer;

- (void)dealloc
{
	[begin release];
	[end release];
	[adapter release];

	[super dealloc];
}

@end
