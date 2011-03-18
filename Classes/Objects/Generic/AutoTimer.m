//
//  AutoTimer.m
//  dreaMote
//
//  Created by Moritz Venn on 18.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimer.h"

@implementation AutoTimer

@synthesize name, match, enabled, idno, from, to, offsetBefore, offsetAfter, encoding, searchType, searchCase, overrideAlternatives, services, bouquets, tags, maxduration, location, justplay, before, after, avoidDuplicateDescription, afterEventAction;

- (void)dealloc
{
	[name release];
	[match release];
	[from release];
	[to release];
	[encoding release];
	[services release];
	[bouquets release];
	[tags release];
	[includeTitle release];
	[includeShortdescription release];
	[includeDescription release];
	[includeDayOfWeek release];
	[excludeTitle release];
	[excludeShortdescription release];
	[excludeDescription release];
	[excludeDayOfWeek release];
	[location release];
	[before release];
	[after release];

	[super dealloc];
}

- (void)addInclude:(NSString *)include where:(autoTimerWhereType)where
{
	switch(where)
	{
		case autoTimerWhereTitle:
			[includeTitle addObject:include];
			break;
		case autoTimerWhereShortdescription:
			[includeShortdescription addObject:include];
			break;
		case autoTimerWhereDescription:
			[includeDescription addObject:include];
			break;
		case autoTimerWhereDayOfWeek:
			[includeDayOfWeek addObject:include];
			break;
		default:
			NSLog(@"Invalid 'where' received: %d", (NSInteger)where);
#if IS_DEBUG()
			[NSException raise:NSInvalidArgumentException format:@"invalid where"];
#endif
			break;
	}
}

- (void)addExclude:(NSString *)exclude where:(autoTimerWhereType)where
{
	switch(where)
	{
		case autoTimerWhereTitle:
			[excludeTitle addObject:exclude];
			break;
		case autoTimerWhereShortdescription:
			[excludeShortdescription addObject:exclude];
			break;
		case autoTimerWhereDescription:
			[excludeDescription addObject:exclude];
			break;
		case autoTimerWhereDayOfWeek:
			[excludeDayOfWeek addObject:exclude];
			break;
		default:
			NSLog(@"Invalid 'where' received: %d", (NSInteger)where);
#if IS_DEBUG()
			[NSException raise:NSInvalidArgumentException format:@"invalid where"];
#endif
			break;
	}
}

@end
