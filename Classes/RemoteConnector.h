/*
 *  RemoteConnector.h
 *  Untitled
 *
 *  Created by Moritz Venn on 08.03.08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

enum availableConnectors {
	kInvalidConnector = -1,
	kEnigma2Connector = 0,
	kEnigma1Connector = 1,
#ifdef ENABLE_NEUTRINO_CONNECTOR
	kNeutrinoConnector = 2,
	kMaxConnector = 3,
#else
	kMaxConnector = 2,
#endif
};

// Ok, this is a little much for just two connectors - but we might want to extend this software even further some day :-)
enum connectorFeatures {
	// Timers can be disabled without removing them
	kFeaturesDisabledTimers = 1,
	// Connector can fetch Record Info
	kFeaturesRecordInfo = 2,
	// Connector can fetch extended information about recordings (e.g. tags)
	kFeaturesExtendedRecordInfo = 3, // XXX: as long as we lack more connectors this is specific enough
	// Connector offers to restart just the remote GUI (not the same as rebooting!)
	kFeaturesGUIRestart = 4,
};

enum buttonCodes {
	kButtonCodePower = 116,
	kButtonCode1 = 2,
	kButtonCode2 = 3,
	kButtonCode3 = 4,
	kButtonCode4 = 5,
	kButtonCode5 = 6,
	kButtonCode6 = 7,
	kButtonCode7 = 8,
	kButtonCode8 = 9,
	kButtonCode9 = 10,
	kButtonCode0 = 11,
	kButtonCodePrevious = 412,
	kButtonCodeNext = 407,
	kButtonCodeVolUp = 115,
	kButtonCodeVolDown = 114,
	kButtonCodeMute = 113,
	kButtonCodeBouquetUp = 402,
	kButtonCodeBouquetDown = 403,
	kButtonCodeLame = 174,
	kButtonCodeInfo = 358,
	kButtonCodeUp = 103,
	kButtonCodeMenu = 139,
	kButtonCodeLeft = 105,
	kButtonCodeOK = 352,
	kButtonCodeRight = 106,
	kButtonCodeAudio = 392,
	kButtonCodeDown = 108,
	kButtonCodeVideo = 393,
	kButtonCodeRed = 398,
	kButtonCodeGreen = 399,
	kButtonCodeYellow = 400,
	kButtonCodeBlue = 401,
	kButtonCodeTV = 377,
	kButtonCodeRadio = 385,
	kButtonCodeText = 388,
	kButtonCodeHelp = 138,
};

#include "Service.h"
#include "Volume.h"
#include "Timer.h"

@protocol RemoteConnector

- (id)initWithAddress:(NSString *) address;
+ (id <RemoteConnector>*)createClassWithAddress:(NSString *) address;
- (const BOOL)hasFeature: (enum connectorFeatures)feature;
- (NSInteger)getMaxVolume;
- (BOOL)isReachable;

- (void)fetchServices:(id)target action:(SEL)action;
- (void)fetchEPG:(id)target action:(SEL)action service:(Service *)service;
- (void)fetchTimers:(id)target action:(SEL)action;
- (void)fetchMovielist:(id)target action:(SEL)action;
- (void)getVolume:(id)target action:(SEL)action;

// XXX: we might want to return a dictionary which contains retval / explain for these
- (BOOL)zapTo:(Service *) service;
- (void)shutdown;
- (void)standby;
- (void)reboot;
- (void)restart;
- (BOOL)toggleMuted;
- (BOOL)setVolume:(NSInteger) newVolume;
- (BOOL)addTimer:(Timer *) newTimer;
- (BOOL)editTimer:(Timer *) oldTimer: (Timer *) newTimer;
- (BOOL)delTimer:(Timer *) oldTimer;
- (BOOL)sendButton:(NSInteger) type;

@end
