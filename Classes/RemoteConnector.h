/*
 *  RemoteConnector.h
 *  Untitled
 *
 *  Created by Moritz Venn on 08.03.08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

enum availableConnectors {
	kEnigma2Connector = 1,
};

enum powerStates {
	kShutdownState = 1,
	kRebootState = 2,
	kRestartGUIState = 3,
};

enum buttonCodes {
	kButtonCodePower = 116,
	kButttonCode1 = 2,
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
	kButtonCodeBouqetUp = 402,
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
- (void)fetchServices:(id)target action:(SEL)action;
- (void)fetchEPG:(id)target action:(SEL)action service:(Service *)service;
- (void)fetchTimers:(id)target action:(SEL)action;
- (void)getVolume:(id)target action:(SEL)action;

// XXX: we might want to return a dictionary which contains retval / explain for these
- (BOOL)zapTo:(Service *) service;
- (void)shutdown;
- (void)standby;
- (void)reboot;
- (void)restart;
- (BOOL)toggleMuted;
- (BOOL)setVolume:(int) newVolume;
- (BOOL)addTimer:(Timer *) newTimer;
- (BOOL)editTimer:(Timer *) oldTimer: (Timer *) newTimer;
- (BOOL)delTimer:(Timer *) oldTimer;
- (BOOL)sendButton:(int) type;

@end
