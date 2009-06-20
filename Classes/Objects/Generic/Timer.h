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

/*!
 @brief Event Types in Neutrino.

 @note We ignore everything except zapto&standby currently but this is here
 in case we need it later.
 @constant neutrinoTimerTypeShutdown Shut STB down.
 @constant neutrinoTimerTypeNextprogram ???
 @constant neutrinoTimerTypeZapto Zap to a given Service.
 @constant neutrinoTimerTypeStandby Enter Standby.
 @constant neutrinoTimerTypeRecord Record a given Service.
 @constant neutrinoTimerTypeRemind ???
 @constant neutrinoTimerTypeSleep ???
 @constant neutrinoTimerTypePlugin ???
 */
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

/*!
 @brief Repeat Flags in Neutrino.

 @constant neutrinoTimerRepeatNever Don't repeat.
 @constant neutrinoTimerRepeatDaily Repeat daily.
 @constant neutrinoTimerRepeatWeekly Repeat every week.
 @constant neutrinoTimerRepeatBiweekly Repeat every two weeks.
 @constant neutrinoTimerRepeatFourweekly Repeat every four weeks.
 @constant neutrinoTimerRepeatMonthly ??? Repeat on this day every month ???
 @constant neutrinoTimerRepeatByDescription ???
 @constant neutrinoTimerRepeatMonday Repeat on Monday.
 @constant neutrinoTimerRepeatTuesday Repeat on Tuesday.
 @constant neutrinoTimerRepeatWednesday Repeat on Wednesday.
 @constant neutrinoTimerRepeatThursday Repeat on Thursday.
 @constant neutrinoTimerRepeatFriday Repeat on Friday.
 @constant neutrinoTimerRepeatSaturday Repeat on Saturday.
 @constant neutrinoTimerRepeatSunday Repeat on Sunday.
 */
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

/*!
 @brief Generic Timer.
 */
@interface Timer : NSObject <TimerProtocol>
{
@private
	NSString *_eit; /*!< @brief Event Id. */
	NSDate *_begin; /*!< @brief Begin. */
	NSDate *_end; /*!< @brief End. */
	BOOL _disabled; /*!< @brief Disabled? */
	NSString *_title; /*!< @brief Title. */
	NSString *_tdescription; /*!< @brief Description. */
	NSInteger _repeated; /*!< @brief Repeated. */
	NSInteger _repeatcount; /*!< @brief ??? */
	BOOL _justplay; /*!< @brief Justplay? */
	NSObject<ServiceProtocol> *_service; /*!< @brief Service. */
	NSString *_sref; /*!< @brief Service Reference. */
	NSString *_sname; /*!< @brief Service Name. */
	NSInteger _state; /*!< @brief State. */
	NSInteger _afterevent; /*!< @brief After Event Action. */
	double _duration; /*!< @brief Event Duration. */
	BOOL _isValid; /*!< @brief Valid or Fake Timer? */
	NSString *_timeString; /*!< @brief ??? */
}

/*!
 @brief Initialize with existing Timer.
 
 @note Required to create a Copy.
 @param timer Existing Timer.
 @return Timer instance.
 */
- (id)initWithTimer:(NSObject<TimerProtocol> *)timer;

/*!
 @brief Create Timer with attributes from given Event.
 
 @param outEvent Event.
 @return Timer instance.
 */
+ (NSObject<TimerProtocol> *)withEvent: (NSObject<EventProtocol> *)ourEvent;

/*!
 @brief Create Timer with attributes from given Event and Service.
 
 @param ourEvent Event.
 @param ourService Service.
 @return Timer instance.
 */
+ (NSObject<TimerProtocol> *)withEventAndService: (NSObject<EventProtocol> *)ourEvent: (NSObject<ServiceProtocol> *)ourService;

/*!
 @brief Create new Timer.

 @return Timer instance.
 */
+ (NSObject<TimerProtocol> *)timer;

@end
