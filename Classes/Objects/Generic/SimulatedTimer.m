//
//  SimulatedTimer.m
//  dreaMote
//
//  Created by Moritz Venn on 09.01.12.
//  Copyright (c) 2012 Moritz Venn. All rights reserved.
//

#import "SimulatedTimer.h"

@implementation SimulatedTimer

@synthesize autotimerName;

- (id)initWithTimer:(NSObject<TimerProtocol> *)timer
{
	if((self = [super initWithTimer:timer]))
	{
		if([timer isKindOfClass:[SimulatedTimer class]])
		{
			self.autotimerName = [((SimulatedTimer *)timer).autotimerName copy];
		}
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n AutoTimer: '%@'.\nBegin: '%@'.\n", [self class], self.title, self.autotimerName, self.begin];
}

- (NSComparisonResult)timeCompare:(SimulatedTimer *)other
{
	NSComparisonResult res = [self.begin compare:other.begin];
	if(res == NSOrderedSame)
	{
		res = [self.title caseInsensitiveCompare:other.title];
		if(res == NSOrderedSame)
			res = [self.service.sname caseInsensitiveCompare:other.service.sname];
	}
	return res;
}

- (NSComparisonResult)autotimerCompare:(SimulatedTimer *)other
{
	NSComparisonResult res = [autotimerName caseInsensitiveCompare:other.autotimerName];
	if(res == NSOrderedSame)
	{
		res = [self.begin compare:other.begin];
		if(res == NSOrderedSame)
			res = [self.service.sname caseInsensitiveCompare:other.service.sname];
	}
	return res;
}

@end
