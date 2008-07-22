//
//  Event.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Event.h"

@implementation Event

@synthesize eit = _eit;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize title = _title;
@synthesize sdescription = _sdescription;
@synthesize edescription = _edescription;

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (void)setBeginFromString: (NSString *)newBegin
{
	[_begin release];
	_begin = [[NSDate dateWithTimeIntervalSince1970: [newBegin doubleValue]] retain];
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	[_end release];
	_end = [[_begin addTimeInterval: [newDuration doubleValue]] retain];
}

@end
