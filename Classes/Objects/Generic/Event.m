//
//  Event.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Event.h"

#import "ServiceProtocol.h"

@implementation GenericEvent

@synthesize service, eit, begin, end, title, sdescription, edescription, timeString;

- (BOOL)isValid
{
	return self.service || (self.begin && self.end);
}

- (id)init
{
	if((self = [super init]))
	{
		_duration = -1;
	}
	return self;
}

- (id)initWithEvent:(NSObject <EventProtocol>*)event
{
	if((self = [super init]))
	{
		// don't try to copy service, only one backend knows it anyway
		self.eit = [event.eit copy];
		self.begin = [event.begin copy];
		self.end = [event.end copy];
		self.title = [event.title copy];
		self.sdescription = [event.sdescription copy];
		self.edescription = [event.edescription copy];
	}
	return self;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (void)setBeginFromString: (NSString *)newBegin
{
	self.timeString = nil;

	self.begin = [NSDate dateWithTimeIntervalSince1970:[newBegin doubleValue]];
	if(_duration != -1){
		self.end = [self.begin dateByAddingTimeInterval:_duration];
		_duration = -1;
	}
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	self.timeString = nil;

	if(self.begin == nil) {
		_duration = [newDuration doubleValue];
		return;
	}
	self.end = [self.begin dateByAddingTimeInterval:[newDuration doubleValue]];
}

- (BOOL)isEqualToEvent: (NSObject<EventProtocol> *)otherEvent
{
	return [self.eit isEqualToString: otherEvent.eit] &&
	[self.title isEqualToString: otherEvent.title] &&
	[self.sdescription isEqualToString: otherEvent.sdescription] &&
	[self.edescription isEqualToString: otherEvent.edescription] &&
	[self.begin isEqualToDate: otherEvent.begin] &&
	[self.end isEqualToDate: otherEvent.end];
}

- (NSComparisonResult)compare: (NSObject<EventProtocol> *)otherEvent
{
	return [otherEvent.begin compare: self.begin];
}


#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] alloc] initWithEvent: self];

	return newElement;
}

@end
