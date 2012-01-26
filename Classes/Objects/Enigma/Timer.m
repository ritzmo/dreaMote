//
//  Timer.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "Timer.h"

@implementation EnigmaTimer

@synthesize typedata;

- (id)initWithTimer:(NSObject<TimerProtocol> *)timer
{
	if((self = [super initWithTimer:timer]))
	{
		if([timer respondsToSelector:@selector(typedata)])
			self.typedata = ((EnigmaTimer *)timer).typedata;
	}
	return self;
}

- (BOOL)isEqualToEvent:(NSObject <EventProtocol>*)event
{
	return NO;
}

- (void)setTypedata:(NSInteger)typeData
{
	// We translate to Enigma2 States here
	if(typeData & stateRunning)
		self.state = kTimerStateRunning;
	else if(typeData & stateFinished)
		self.state = kTimerStateFinished;
	else // stateWaiting or unknown
		self.state =  kTimerStateWaiting;

	if(typeData & doGoSleep)
		self.afterevent = kAfterEventStandby;
	else if(typeData & doShutdown)
		self.afterevent = kAfterEventDeepstandby;
	else
		self.afterevent = kAfterEventNothing;

	if(typeData & SwitchTimerEntry)
		self.justplay = YES;
	else // We assume RecTimerEntry here
		self.justplay = NO;

	if(typeData & isRepeating)
	{
		if(typeData & Su)
			self.repeated |= weekdaySun;
		if(typeData & Mo)
			self.repeated |= weekdayMon;
		if(typeData & Tue)
			self.repeated |= weekdayTue;
		if(typeData & Wed)
			self.repeated |= weekdayWed;
		if(typeData & Thu)
			self.repeated |= weekdayThu;
		if(typeData & Fr)
			self.repeated |= weekdayFri;
		if(typeData & Sa)
			self.repeated |= weekdaySat;
	}
	else
		self.repeated = 0;
	typedata = typeData;
}

@end
