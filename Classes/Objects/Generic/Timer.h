//
//  Timer.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EventProtocol.h"
#import "TimerProtocol.h"
#import "ServiceProtocol.h"

// XXX: we ignore everything except zapto&standby currently but this is here in case we need it later
enum neutrinoEventType {
	neutrinoTimerTypeShutdown = 1,
	neutrinoTimerTypeNextprogram = 2,
	neutrinoTimerTypeZapto = 3,
	neutrinoTimerTypeStandby = 4,
	neutrinoTimerTypeRecord = 5,
	neutrinoTimerTypeRemind = 6,
	neutrinoTimerTypeSleep = 7,
	neutrinoTimerTypePlugin = 8,
};

enum neutrinoTimerRepeat {
	neutrinoTimerRepeatNever = 0,
	neutrinoTimerRepeatDaily = 1,
	neutrinoTimerRepeatWeekly = 2,
	neutrinoTimerRepeatBiweekly = 3,
	neutrinoTimerRepeatFourweekly = 4,
	neutrinoTimerRepeatMonthly = 5,
	neutrinoTimerRepeatByDescription = 6, // XXX: unimpl in neutrino?
	neutrinoTimerRepeatMonday = 256,
	neutrinoTimerRepeatTuesday = 512,
	neutrinoTimerRepeatWednesday = 1024,
	neutrinoTimerRepeatThursday = 2048,
	neutrinoTimerRepeatFriday = 4096,
	neutrinoTimerRepeatSaturday = 8192,
	neutrinoTimerRepeatSunday = 16384,
};

@interface Timer : NSObject <TimerProtocol>
{
@private
	NSString *_eit;
	NSDate *_begin;
	NSDate *_end;
	BOOL _disabled;
	NSString *_title;
	NSString *_tdescription;
	NSInteger _repeated;
	NSInteger _repeatcount;
	BOOL _justplay;
	NSObject<ServiceProtocol> *_service;
	NSString *_sref;
	NSString *_sname;
	NSInteger _state;
	NSInteger _afterevent;
	double _duration;
	BOOL _isValid;
	NSString *_timeString;
}

- (id)initWithTimer:(NSObject<TimerProtocol> *)timer;

+ (NSObject<TimerProtocol> *)withEvent: (NSObject<EventProtocol> *)ourEvent;
+ (NSObject<TimerProtocol> *)withEventAndService: (NSObject<EventProtocol> *)ourEvent: (NSObject<ServiceProtocol> *)ourService;
+ (NSObject<TimerProtocol> *)timer;

@end
