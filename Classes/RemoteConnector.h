/*
 *  RemoteConnector.h
 *  dreaMote
 *
 *  Created by Moritz Venn on 08.03.08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

enum availableConnectors {
	kInvalidConnector = -1,
	kEnigma2Connector = 0,
	kEnigma1Connector = 1,
	kNeutrinoConnector = 2,
	kSVDRPConnector = 3,
	kMaxConnector = 4,
};

enum screenshotType {
	kScreenshotTypeBoth = 0,
	kScreenshotTypeOSD = 1,
	kScreenshotTypeVideo = 2,
};

enum connectorFeatures {
	// Timers can be disabled without removing them
	kFeaturesDisabledTimers,
	// Timer can have an "after Event"-Action
	kFeaturesTimerAfterEvent,
	// Timer can have "Auto" as "after Event"-Action
	kFeaturesTimerAfterEventAuto,
	// Connector can fetch Record Info
	kFeaturesRecordInfo,
	// Connector can fetch extended information about recordings (e.g. tags)
	kFeaturesExtendedRecordInfo, // XXX: as long as we lack more connectors this is specific enough
	// Connector offers to restart just the remote GUI (not the same as rebooting!)
	kFeaturesGUIRestart,
	// Can give a message type
	kFeaturesMessageType,
	// Can set a custom caption for messages
	kFeaturesMessageCaption,
	// Can provide a custom timeout
	kFeaturesMessageTimeout,
	// Can fetch a Screenshot of the GUI
	kFeaturesScreenshot,
	// Can fetch a Screenshot of just the video buffer
	kFeaturesVideoScreenshot,
	// Remote Control has all buttons (we have a simple and a "full" view)
	kFeaturesFullRemote,
	// Remote Control of DM8000 *grml*
	kFeaturesAdvancedRemote,
	// Has a single bouquet mode
	kFeaturesSingleBouquet,
	// Timer Id is a constant
	kFeaturesConstantTimerId,
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

@class Volume;
@protocol MovieProtocol;
@protocol ServiceProtocol;
@protocol TimerProtocol;

@class CXMLDocument;

@protocol RemoteConnector

// General
- (id)initWithAddress:(NSString *) address andUsername: (NSString *)username andPassword: (NSString *)password andPort: (NSInteger)port;
+ (NSObject <RemoteConnector>*)createClassWithAddress:(NSString *) address andUsername: (NSString *)username andPassword: (NSString *)password andPort: (NSInteger)port;
- (const BOOL)hasFeature: (enum connectorFeatures)feature;
- (NSInteger)getMaxVolume;
- (BOOL)isReachable;

// Data sources
- (CXMLDocument *)fetchBouquets:(id)target action:(SEL)action;
- (CXMLDocument *)fetchServices:(id)target action:(SEL)action bouquet:(NSObject<ServiceProtocol> *)bouquet;
- (CXMLDocument *)fetchEPG:(id)target action:(SEL)action service:(NSObject<ServiceProtocol> *)service;
- (CXMLDocument *)fetchTimers:(id)target action:(SEL)action;
- (CXMLDocument *)fetchMovielist:(id)target action:(SEL)action;
- (void)getVolume:(id)target action:(SEL)action;
- (NSData *)getScreenshot: (enum screenshotType)type;

// Functions
// XXX: we might want to return a dictionary which contains retval / explain for these
- (BOOL)zapTo:(NSObject<ServiceProtocol> *) service;
- (BOOL)playMovie:(NSObject<MovieProtocol> *) movie;
- (void)shutdown;
- (void)standby;
- (void)reboot;
- (void)restart;
- (BOOL)toggleMuted;
- (BOOL)setVolume:(NSInteger) newVolume;
- (BOOL)addTimer:(NSObject<TimerProtocol> *) newTimer;
- (BOOL)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer;
- (BOOL)delTimer:(NSObject<TimerProtocol> *) oldTimer;
- (BOOL)sendButton:(NSInteger) type;
- (BOOL)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout;

// Helper GUI
- (NSInteger)getMaxMessageType;
- (NSString *)getMessageTitle: (NSInteger)type;
- (void)openRCEmulator: (UINavigationController *)navigationController;

// Misc
- (void)freeCaches;

@end
