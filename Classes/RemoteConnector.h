//
//  RemoteConnector.h
//  dreaMote
//
//  Contains Interface declaration and common enums.
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

/*!
 @brief Enum describing the various available connectors.
 @note The associated connector of a connection is saved as this Id.
 */
enum availableConnectors {
	kInvalidConnector = -1, /*!< @brief Not actually a valid connector. */
	kEnigma2Connector = 0, /*!< @brief Enigma2. */
	kEnigma1Connector = 1, /*!< @brief Enigma. */
	kNeutrinoConnector = 2, /*!< @brief Neutrino. */
	kSVDRPConnector = 3, /*!< @brief SVDRP. */
	kMaxConnector = 4, /*!< @brief Upper boudn of connectors. */
};

/*!
 @brief Simple enum describing the available types of screenshots.
 */
enum screenshotType {
	kScreenshotTypeBoth = 0, /*!< @brief Screenshot containing both osd & video. */
	kScreenshotTypeOSD = 1, /*!< @brief Screenshot containing only osd. */
	kScreenshotTypeVideo = 2, /*!< @brief Screenshot containing only video. */
};

/*!
 @brief Implemented connector features.
 @note To describe the available features of a connector this enum is used,
 you can check any of the feature against the hasFeature function.
 */ 
enum connectorFeatures {
	/*! @brief Timers can be disabled without removing them. */
	kFeaturesDisabledTimers,
	/*! @brief Timer can have an "after Event"-Action. */
	kFeaturesTimerAfterEvent,
	/*! @brief Timer can have "Auto" as "after Event"-Action. */
	kFeaturesTimerAfterEventAuto,
	/*! @brief Connector can fetch Record Info. */
	kFeaturesRecordInfo,
	/*!
	 @brief Connector can fetch extended information about recordings (e.g. tags).
	 @note As long as we lack more connectors this is specific enough
	 */
	kFeaturesExtendedRecordInfo,
	/*! @brief Connector can delete recordings. */
	kFeaturesRecordDelete,
	/*! @brief Connector offers to restart just the remote GUI (not the same as rebooting!). */
	kFeaturesGUIRestart,
	/*! @brief Can give a message type. */
	kFeaturesMessageType,
	/*! @brief Can set a custom caption for messages. */
	kFeaturesMessageCaption,
	/*! @brief Can provide a custom timeout. */
	kFeaturesMessageTimeout,
	/*! @brief Can fetch a Screenshot of the GUI. */
	kFeaturesScreenshot,
	/*! @brief Can fetch a Screenshot of just the video buffer. */
	kFeaturesVideoScreenshot,
	/*! @brief Remote Control of DM8000 *grml*. */
	kFeaturesAdvancedRemote,
	/*! @brief Has support for bouquets. */
	kFeaturesBouquets,
	/*! @brief Has a single bouquet mode. */
	kFeaturesSingleBouquet,
	/*! @brief Timer Id is a constant. */
	kFeaturesConstantTimerId,
	/*! @brief Can sarch EPG. */
	kFeaturesEPGSearch,
	/*! @brief Allows to start an instant record. */
	kFeaturesInstantRecord,
	/*! @brief Offers a SatFinder. */
	kFeaturesSatFinder,
	/*! @brief Similar EPG search. */
	kFeaturesEPGSearchSimilar,
	/*!
	 @brief "Simple" Repeated timers
	 "Simple" means not complicated like "biweekly mondays and thursdays".

	 @note this is more of a hack to allow an implementation in enigma(2) without having
	 to bother about neutrino/svdrp :-)
	 */
	kFeaturesSimpleRepeated,
	/*! @brief Allows to display currently playing service and event. */
	kFeaturesCurrent,
	/*! @brief Supports radio mode. */
	kFeaturesRadioMode,
};

/*!
 @brief Button codes for emulated remote control.
 @note The keyset and keycodes equal the ones from Enigma2 with a standard remote.
 */
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
	// Advanced Remote
	kButtonCodeRecord = 167,
	kButtonCodePVR = 393,
	kButtonCodePlayPause = 164,
	kButtonCodeFFwd = 159,
	kButtonCodeFRwd = 168,
	kButtonCodeStop = 128,
	
};


// Forward declarations...
@class CXMLDocument;
@class Result;
@protocol EventProtocol;
@protocol MovieProtocol;
@protocol ServiceProtocol;
@protocol TimerProtocol;
@protocol EventSourceDelegate;
@protocol MovieSourceDelegate;
@protocol ServiceSourceDelegate;
@protocol SignalSourceDelegate;
@protocol TimerSourceDelegate;
@protocol VolumeSourceDelegate;



/*!
 @brief Protocol of Connectors.

 Every Connector has to implement this Protocol which allows us to interact with
 same through a Standard API.
 */
@protocol RemoteConnector

// General functions
/*!
 @brief Initialize Connector with host, username, password and port.
 
 @param address Name or IP of Remote Host.
 @param username Username on Remote Host.
 @param password Password on Remote Host.
 @param port Port on Remote Host.
 @param ssl Whether or not the connection is encrypted.
 @return RemoteConnector Object.
 */
- (id)initWithAddress:(NSString *) address andUsername: (NSString *)username andPassword: (NSString *)password andPort: (NSInteger)port useSSL: (BOOL)ssl;

/*!
 @brief Standard constructor for RemoteConnectors.
 
 @param address Name or IP of Remote Host.
 @param username Username on Remote Host.
 @param password Password on Remote Host.
 @param port Port on Remote Host.
 @param ssl Whether or not the connection is encrypted.
 @return RemoteConnector Object.
 */
+ (NSObject <RemoteConnector>*)newWithAddress:(NSString *) address andUsername: (NSString *)username andPassword: (NSString *)password andPort: (NSInteger)port useSSL: (BOOL)ssl;

/*!
 @brief Check if a Connector supports a given Feature.
 
 @param feature Feature to check for.
 @return YES if this Feature is supported.
 */
- (const BOOL const)hasFeature: (enum connectorFeatures)feature;

/*!
 @brief Returns upper bound of Volume setting.
 
 @return Upper bound of Volume.
 */
- (const NSUInteger const)getMaxVolume;

/*!
 @brief Returns whether to Receiver is currently reachable or not.
 @note This Function is also used by the Autodetection.

 @return YES if the Receiver is reachable and verified as compatible with the Connector.
 */
- (BOOL)isReachable;



// Data sources
/*!
 @brief Fetch list of available Bouquets.
 
 @param delegate Delegate to be called back.
 @param isRadio Fetch radio bouquets?
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)fetchBouquets: (NSObject<ServiceSourceDelegate> *)delegate isRadio:(BOOL)isRadio;

/*!
 @brief Fetch Services of a given Bouquet.
 @note If no bouquet is given the Connector can choose to return the default bouquet.
 
 @param delegate Delegate to be called back.
 @param bouquet Bouquet to request Services of.
 @param isRadio Fetch radio services?
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)fetchServices: (NSObject<ServiceSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio;

/*!
 @brief Request EPG of given Service from Receiver.
 
 @param delegate Delegate to be called back.
 @param service Service to fetch EPG of.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)fetchEPG: (NSObject<EventSourceDelegate> *)delegate service:(NSObject<ServiceProtocol> *)service;

/*!
 @brief Request Timerlist from the Receiver.
 
 @param delegate Delegate to be called back.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)fetchTimers: (NSObject<TimerSourceDelegate> *)delegate;

/*!
 @brief Request Movielist from the Receiver.
 
 @param delegate Delegate to be called back.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)fetchMovielist: (NSObject<MovieSourceDelegate> *)delegate;

/*!
 @brief Get current Volume settings.
 
 @param delegate Delegate to be called back.
 */
- (void)getVolume: (NSObject<VolumeSourceDelegate> *)delegate;

/*!
 @brief Get current Signal Strength.
 
 @param delegate Delegate to be called back.
 */
- (void)getSignal: (NSObject<SignalSourceDelegate> *)delegate;

/*!
 @brief Request a Screnshot from the Receiver.

 @param type Requested Screenshot type.
 @return Pointer to Screenshot or nil on failure.
 */
- (NSData *)getScreenshot: (enum screenshotType)type;

/*!
 @brief Invoke an EPG Search for Title.
 @note The Search is currently hardcoded to a case-insensitive search in ISO8859-15.

 @param delegate Delegate to be called back.
 @param title Text to Search in Event Titles.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)searchEPG: (NSObject<EventSourceDelegate> *)delegate title:(NSString *)title;

/*!
 @brief Search EPG for Similar Events.
 @note Currently this needs support on the Receiver and therefore is only supported
 on Enigma2.
 
 @param delegate Delegate to be called back.
 @param event Event to search similar events of.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)searchEPGSimilar: (NSObject<EventSourceDelegate> *)delegate event:(NSObject<EventProtocol> *)event;

/*!
 @brief Get information on currently playing service and now/new event.
 
 @param delegate Delegate to be called back.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)getCurrent: (NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate;

// Functions
/*!
 @brief Zap to given service.

 @param service Service to zap to.
 @return YES if zapping succeeded.
 */
- (Result *)zapTo:(NSObject<ServiceProtocol> *) service;

/*!
 @brief Start playback of given movie.
 
 @param movie Movie to start playback of.
 @return YES if starting playback succeeded.
 */
- (Result *)playMovie:(NSObject<MovieProtocol> *) movie;

/*!
 @brief Delete a given Movie from Receiver HDD.
 
 @param movie Movie to delete.
 @return YES if deletion succeeded.
 */
- (Result *)delMovie:(NSObject<MovieProtocol> *) movie;

/*!
 @brief Invoke Shutdown procedure of Receiver.
 */
- (void)shutdown;

/*!
 @brief Invoke Standby of Receiver.
 */
- (void)standby;

/*!
 @brief Invoke Reboot of Receiver.
 */
- (void)reboot;

/*!
 @brief Invoke GUI Restart of Receiver.
 */
- (void)restart;

/*!
 @brief Toggle Muted status on Receiver.

 @return YES if audio is muted at the end of this function.
 */
- (BOOL)toggleMuted;

/*!
 @brief Set Volume to new level.
 
 @param newVolume Volume level to set.
 @return YES if change succeeded.
 */
- (Result *)setVolume:(NSInteger) newVolume;

/*!
 @brief Schedule a Timer for recording on Receiver.
 
 @param newTimer Timer to add.
 @return YES if Timer was added successfully.
 */
- (Result *)addTimer:(NSObject<TimerProtocol> *) newTimer;

/*!
 @brief Change existing Timer.
 
 @param oldTimer Existing Timer to change.
 @param newTimer New values for Timer.
 @return YES if Timer was changed successfully.
 */
- (Result *)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer;

/*!
 @brief Remove a Timer on Receiver.
 
 @param oldTimer Timer to remove.
 @return YES if Timer was removed.
 */
- (Result *)delTimer:(NSObject<TimerProtocol> *) oldTimer;

/*!
 @brief Send Remote Control Code to Receiver.
 
 @param type Button Code.
 @return YES if code was sent successfully.
 */
- (Result *)sendButton:(NSInteger) type;

/*!
 @brief Send GUI Message to Receiver.
 
 @param message Message text.
 @param caption Message caption (not supported by all Connectors).
 @param type Message type (not supported by all Connectors).
 @param timeout Message timeout.
 @return YES if message was sent successfully.
 */
- (Result *)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout;

/*!
 @brief Start instant Record on Receiver.
 
 @return YES if record was started.
 */
- (Result *)instantRecord;



// Helper GUI
/*!
 @brief Returns upper bound for message types supported by Connector.
 
 @return Upper bound of message types.
 */
- (const NSUInteger const)getMaxMessageType;

/*!
 @brief Textual representation of given message type.
 
 @param type Message type.
 @return Textual Representation.
 */
- (NSString *)getMessageTitle: (NSUInteger)type;

/*!
 @brief Open Remote Control Emulator of Connector.
 
 @param navigationController UINavigationController instance.
 */
- (void)openRCEmulator: (UINavigationController *)navigationController;



// Misc
/*!
 @brief Free Caches used by Backend.
 @note This function is used by some Backends to free Ressources that are
 cached during Runtime and freed when running low on memory.
 */
- (void)freeCaches;

@end
