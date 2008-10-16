//
//  Timer.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Service.h"
#import "Event.h"

enum afterEvent {
	kAfterEventNothing = 0,
	kAfterEventStandby = 1,
	kAfterEventDeepstandby = 2,
	kAfterEventMax = 3
};

enum timerStates {
	kTimerStateWaiting = 0,
	kTimerStatePrepared = 1,
	kTimerStateRunning = 2,
	kTimerStateFinished = 3,
	kTimerStateMax = 4
};

// TODO: check what we actually need :-)
enum timerType {
// PlaylistEntry types
	PlaylistEntry=1,       // normal PlaylistEntry (no Timerlist entry)
	SwitchTimerEntry=2,    // simple service switch timer
	RecTimerEntry=4,       // timer do recording
// Recording subtypes
	recDVR=8,	      // timer do DVR recording
	recVCR=16,	     // timer do VCR recording (LIRC) not used yet
	recNgrab=131072,       // timer do record via Ngrab Server
// Timer States
	stateWaiting=32,       // timer is waiting
	stateRunning=64,       // timer is running
	statePaused=128,       // timer is paused
	stateFinished=256,     // timer is finished
	stateError=512,	// timer has error state(s)
// Timer Error states
	errorNoSpaceLeft=1024, // HDD no space Left ( recDVR )
	errorUserAborted=2048, // User Action aborts this event
	errorZapFailed=4096,   // Zap to service failed
	errorOutdated=8192,    // Outdated event
						     // box was switched off during the event
//  advanced entry propertys
	boundFile=16384,	// Playlistentry have an bounded file
	isSmartTimer=32768,     // this is a smart timer (EIT related) not uses Yet
	isRepeating=262144,     // this timer is repeating
	doFinishOnly=65536,     // Finish an running event/action
							// this events are automatically removed
							// from the timerlist after finish
	doShutdown=67108864,    // timer shutdown the box
	doGoSleep=134217728,    // timer set box to standby
//  Repeated Timer Days
	Su=524288, Mo=1048576, Tue=2097152,
	Wed=4194304, Thu=8388608, Fr=16777216, Sa=33554432
};

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

@interface Timer : NSObject
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
	Service *_service;
	NSString *_sref;
	NSString *_sname;
	NSInteger _state;
	NSInteger _afterevent;
	double _duration;
}

+ (Timer *)withEvent: (Event *)ourEvent;
+ (Timer *)withEventAndService: (Event *)ourEvent: (Service *)ourService;
+ (Timer *)timer;

- (NSString *)getStateString;
- (NSInteger)getEnigmaAfterEvent;
- (void)setBeginFromString: (NSString *)newBegin;
- (void)setEndFromString: (NSString *)newEnd;
- (void)setEndFromDurationString: (NSString *)newDuration;

@property (nonatomic, retain) NSString *eit;
@property (nonatomic, retain) NSDate *begin;
@property (nonatomic, retain) NSDate *end;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *tdescription;
@property (assign) BOOL disabled;
@property (assign) NSInteger repeated;
@property (assign) NSInteger repeatcount;
@property (assign) BOOL justplay;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) NSString *sref;
@property (nonatomic, retain) NSString *sname;
@property (assign) NSInteger state;
@property (assign) NSInteger afterevent;

@end
