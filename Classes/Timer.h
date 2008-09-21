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
	kAfterEventDeepstandby = 2
};

enum timerStates {
	kTimerStateWaiting = 0,
	kTimerStatePrepared = 1,
	kTimerStateRunning = 2,
	kTimerStateFinished = 3,
	kTimerStateMax = 4
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
	BOOL _justplay;
	Service *_service;
	NSString *_sref;
	NSInteger _state;
	NSInteger _afterevent;
	double _duration;
}

+ (Timer *)withEvent: (Event *)ourEvent;
+ (Timer *)withEventAndService: (Event *)ourEvent: (Service *)ourService;
+ (Timer *)new;

- (NSString *)getStateString;
- (void)setBeginFromString: (NSString *)newBegin;
- (void)setEndFromString: (NSString *)newEnd;
- (void)setEndFromDurationString: (NSString *)newDuration;
- (void)setDisabledFromString: (NSString *)newDisabled;
- (void)setJustplayFromString: (NSString *)newJustplay;
- (void)setRepeatedFromString: (NSString *)newRepeated;
- (void)setServiceFromSname: (NSString *)newSname;
- (void)setStateFromString: (NSString *)newState;
- (void)setAftereventFromString: (NSString *)newAfterevent;

@property (nonatomic, retain) NSString *eit;
@property (nonatomic, retain) NSDate *begin;
@property (nonatomic, retain) NSDate *end;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *tdescription;
@property (assign) BOOL disabled;
@property (assign) NSInteger repeated;
@property (assign) BOOL justplay;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) NSString *sref;
@property (assign) NSInteger state;
@property (assign) NSInteger afterevent;

@end
