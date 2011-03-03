//
//  TimerProtocol.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Possible After Event Actions.

 @note kAfterEventAuto is not necessarily available as it is only supported by the
 Enigma2 based STBs.
 @see connectorFeatures
 */
enum afterEvent {
	kAfterEventNothing = 0, /*!< @brief Do nothing after recording. */
	kAfterEventStandby = 1, /*!< @brief Go to standby after recording. */
	kAfterEventDeepstandby = 2, /*!< @brief Shut down after recording. */
	 /*!
	  @brief Go to mode before recording.
	  @see kFeaturesTimerAfterEventAuto
	  */
	kAfterEventAuto = 3,
	kAfterEventMax = 4 /*!< @brief Upper bound of After Event Actions. */
};

/*!
 @brief Possible Timer states.
 */
enum timerStates {
	kTimerStateWaiting = 0, /*!< @brief Waiting for activation. */
	kTimerStatePrepared = 1, /*!< @brief About to start. */
	kTimerStateRunning = 2, /*!< @brief Currently running. */
	kTimerStateFinished = 3, /*!< @brief Finished. */
	kTimerStateMax = 4 /*!< @brief Upper bound of Timer states. */
};

/*!
 @brief Enigma1 enum describing timer flags.

 @todo check what we actually need :-)
 */
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

/*!
 @brief Common representation of Weekdays.
 
 @note Equal to values of Enigma2 repeated Timers.
 */
enum weekDays {
	weekdayMon = 1 << 0, /*!< @brief Monday. */
	weekdayTue = 1 << 1, /*!< @brief Tuesday. */
	weekdayWed = 1 << 2, /*!< @brief Wednesday. */
	weekdayThu = 1 << 3, /*!< @brief Thursday. */
	weekdayFri = 1 << 4, /*!< @brief Friday. */
	weekdaySat = 1 << 5, /*!< @brief Saturday. */
	weekdaySun = 1 << 6, /*!< @brief Sunday. */
};

// Forward declaration
@protocol EventProtocol;
@protocol ServiceProtocol;

/*!
 @brief Protocol of a Timer.
 */
@protocol TimerProtocol

/*!
 @brief Return State as a String.
 
 @return String containing state.
 */
- (NSString *)getStateString;

/*!
 @brief Compare timer settings to an event.

 @return YES if the settings are equal, else NO.
*/
- (BOOL)isEqualToEvent:(NSObject<EventProtocol> *)event;

/*!
 @brief Set Begin from Timestamp as String.
 
 @param newBegin String with Unix Timestamp of Begin.
 */
- (void)setBeginFromString: (NSString *)newBegin;

/*!
 @brief Set End from Timestamp as String.
 
 @param newEnd String with Unix Timestamp of End.
 */
- (void)setEndFromString: (NSString *)newEnd;

/*!
 @brief Set End based on a duration provided as String.
 
 @param String with Unix Timestamp of Duration.
 */
- (void)setEndFromDurationString: (NSString *)newDuration;



/*!
 @brief Associated event Id.
 */
@property (nonatomic, retain) NSString *eit;

/*!
 @brief Begin.
 */
@property (nonatomic, retain) NSDate *begin;

/*!
 @brief End.
 */
@property (nonatomic, retain) NSDate *end;

/*!
 @brief Title.
 */
@property (nonatomic, retain) NSString *title;

/*!
 @brief Description.
 */
@property (nonatomic, retain) NSString *tdescription;

/*!
 @brief Disabled.

 @note YES means disabled.
 */
@property (assign) BOOL disabled;

/*!
 @brief Repeated.
 
 0 means not-repeated, everything else is a set of weekdays as described by enum weekDays.
 @note Connectors without kFeaturesSimpleRepeated Feature may keep an unconverted value here.
 */
@property (assign) NSInteger repeated;

/*!
 @brief How many repetitions did this Timer record?
 */
@property (assign) NSInteger repeatcount;

/*!
 @brief Zap-Timer?

 @note YES indicates a non-recording timer.
 */
@property (assign) BOOL justplay;

/*!
 @brief Service.
 */
@property (nonatomic, retain) NSObject<ServiceProtocol> *service;

/*!
 @brief Service Reference.
 
 @note May be used as cache when generating service.
 */
@property (nonatomic, retain) NSString *sref;

/*!
 @brief Service Name.
 
 @note May be used as cache when generating service.
 */
@property (nonatomic, retain) NSString *sname;

/*!
 @brief Current state.
 @see timerStates
 */
@property (assign) NSInteger state;

/*!
 @brief After Event Action.
 @see afterEvent
 */
@property (assign) NSInteger afterevent;

/*!
 @brief Record location
 */
@property (nonatomic, retain) NSString *location;

/*!
 @brief Valid or Fake Timer?
 */
@property (nonatomic, assign) BOOL valid;

/*!
 @brief Good question... :-)
 */
@property (nonatomic, retain) NSString *timeString;

@end
