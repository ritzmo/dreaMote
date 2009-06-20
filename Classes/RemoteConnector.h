//
//  RemoteConnector.h
//  dreaMote
//
//  Contains Interface declaration and common enums.
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

/*!
 @brief Enum describing the various available connectors.
 @note The associated connector of a connection is saved as this Id.
 
 @constant kInvalidConnector not actually a valid connector
 @constant kEnigma2Connector enigma2
 @constant kEnigma1Connector enigma
 @constant kNeutrinoConnector neutrino
 @constant kSVDRPConnector svdrp
 @constant kMaxConnector upper bound of connectors
 */
enum availableConnectors {
	kInvalidConnector = -1,
	kEnigma2Connector = 0,
	kEnigma1Connector = 1,
	kNeutrinoConnector = 2,
	kSVDRPConnector = 3,
	kMaxConnector = 4,
};

/*!
 @brief Simple enum describing the available types of screenshots.
 @constant kScreenshotTypeBoth screenshot containing both osd & video
 @constant kScreenshotTypeOSD screenshot containing only osd
 @constant kScreenshotTypeVideo screenshot containing only video
 */
enum screenshotType {
	kScreenshotTypeBoth = 0,
	kScreenshotTypeOSD = 1,
	kScreenshotTypeVideo = 2,
};

/*!
 @brief Implemented connector features.
 @note To describe the available features of a connector this enum is used,
 you can check any of the feature against the hasFeature function.
 
 @constant kFeaturesDisabledTimers Timers can be disabled without removing them
 @constant kFeaturesTimerAfterEvent Timer can have an "after Event"-Action
 @constant kFeaturesTimerAfterEventAuto Timer can have "Auto" as "after Event"-Action
 @constant kFeaturesRecordInfo Connector can fetch Record Info
 @constant kFeaturesExtendedRecordInfo Connector can fetch extended information about recordings (e.g. tags)
 @constant kFeaturesRecordDelete Connector can delete recordings
 @constant kFeaturesGUIRestart Connector offers to restart just the remote GUI (not the same as rebooting!)
 @constant kFeaturesMessageType Can give a message type
 @constant kFeaturesMessageCaption Can set a custom caption for messages
 @constant kFeaturesMessageTimeout Can provide a custom timeout
 @constant kFeaturesScreenshot Can fetch a Screenshot of the GUI
 @constant kFeaturesVideoScreenshot Can fetch a Screenshot of just the video buffer
 @constant kFeaturesAdvancedRemote Remote Control of DM8000 *grml*
 @constant kFeaturesBouquets Has support for bouquets
 @constant kFeaturesSingleBouquet Has a single bouquet mode
 @constant kFeaturesConstantTimerId Timer Id is a constant
 @constant kFeaturesEPGSearch Can sarch EPG
 @constant kFeaturesInstantRecord Allows to start an instant record
 @constant kFeaturesSatFinder Offers a SatFinder
 @constant kFeaturesEPGSearchSimilar Similar EPG search
 @constant kFeaturesSimpleRepeated "Simple" Repeated timers (as in nothing weird like "biweekly mondays and thursdays")
 */ 
enum connectorFeatures {
	kFeaturesDisabledTimers,
	kFeaturesTimerAfterEvent,
	kFeaturesTimerAfterEventAuto,
	kFeaturesRecordInfo,
	// XXX: as long as we lack more connectors this is specific enough
	kFeaturesExtendedRecordInfo, 
	kFeaturesRecordDelete,
	kFeaturesGUIRestart,
	kFeaturesMessageType,
	kFeaturesMessageCaption,
	kFeaturesMessageTimeout,
	kFeaturesScreenshot,
	kFeaturesVideoScreenshot,
	kFeaturesAdvancedRemote,
	kFeaturesBouquets,
	kFeaturesSingleBouquet,
	kFeaturesConstantTimerId,
	kFeaturesEPGSearch,
	kFeaturesInstantRecord,
	kFeaturesSatFinder,
	kFeaturesEPGSearchSimilar,
	// NOTE: this is more of a hack to allow an implementation in enigma(2) without having
	//       to bother about neutrino/svdrp :-)
	kFeaturesSimpleRepeated,
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
};


// Forward declarations...
@class Volume;
@class CXMLDocument;
@protocol MovieProtocol;
@protocol ServiceProtocol;
@protocol TimerProtocol;
@protocol EventProtocol;



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
 @return RemoteConnector Object.
 */
- (id)initWithAddress:(NSString *) address andUsername: (NSString *)username andPassword: (NSString *)password andPort: (NSInteger)port;

/*!
 @brief Standard constructor for RemoteConnectors.
 
 @param address Name or IP of Remote Host.
 @param username Username on Remote Host.
 @param password Password on Remote Host.
 @param port Port on Remote Host.
 @return RemoteConnector Object.
 */
+ (NSObject <RemoteConnector>*)createClassWithAddress:(NSString *) address andUsername: (NSString *)username andPassword: (NSString *)password andPort: (NSInteger)port;

/*!
 @brief Check if a Connector supports a given Feature.
 
 @param feature Feature to check for.
 @return YES if this Feature is supported.
 */
- (const BOOL)hasFeature: (enum connectorFeatures)feature;

/*!
 @brief Returns upper bound of Volume setting.
 
 @return Upper bound of Volume.
 */
- (NSInteger)getMaxVolume;

/*!
 @brief Returns whether to Receiver is currently reachable or not.
 @note This Function is also used by the Autodetection.

 @return YES if the Receiver is reachable and verified as compatible with the Connector.
 */
- (BOOL)isReachable;



// Data sources
/*!
 @brief Fetch list of available Bouquets.
 
 @param target Object to perform callback on.
 @param action Callback function.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)fetchBouquets:(id)target action:(SEL)action;

/*!
 @brief Fetch Services of a given Bouquet.
 @note If no bouquet is given the Connector can choose to return the default bouquet.
 
 @param target Object to perform callback on.
 @param action Callback function.
 @param bouquet Bouquet to request Services of.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)fetchServices:(id)target action:(SEL)action bouquet:(NSObject<ServiceProtocol> *)bouquet;

/*!
 @brief Request EPG of given Service from Receiver.
 
 @param target Object to perform callback on.
 @param action Callback function.
 @param service Service to fetch EPG of.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)fetchEPG:(id)target action:(SEL)action service:(NSObject<ServiceProtocol> *)service;

/*!
 @brief Request Timerlist from the Receiver.
 
 @param target Object to perform callback on.
 @param action Callback function.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)fetchTimers:(id)target action:(SEL)action;

/*!
 @brief Request Movielist from the Receiver.
 
 @param target Object to perform callback on.
 @param action Callback function.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)fetchMovielist:(id)target action:(SEL)action;

/*!
 @brief Get current Volume settings.
 
 @param target Object to perform callback on.
 @param action Callback function.
 */
- (void)getVolume:(id)target action:(SEL)action;

/*!
 @brief Get current Signal Strength.
 
 @param target Object to perform callback on.
 @param action Callback function.
 */
- (void)getSignal:(id)target action:(SEL)action;

/*!
 @brief Request a Screnshot from the Receiver.

 @param type Requested Screenshot type.
 @return Pointer to Screenshot or nil on failure.
 */
- (NSData *)getScreenshot: (enum screenshotType)type;

/*!
 @brief Invoke an EPG Search for Title.
 @note The Search is currently hardcoded to a case-insensitive search in ISO8859-15.

 @param target Object to perform callback on.
 @param action Callback function.
 @param title Text to Search in Event Titles.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)searchEPG:(id)target action:(SEL)action title:(NSString *)title;

/*!
 @brief Search EPG for Similar Events.
 @note Currently this needs support on the Receiver and therefore is only supported
 on Enigma2.
 
 @param target Object to perform callback on.
 @param action Callback function.
 @param event Event to search similar events of.
 @return Pointer to parsed CXMLDocument.
 */
- (CXMLDocument *)searchEPGSimilar:(id)target action:(SEL)action event:(NSObject<EventProtocol> *)event;



// Functions
// XXX: we might want to return a dictionary which contains retval / explain for these
/*!
 @brief Zap to given service.

 @param service Service to zap to.
 @return YES if zapping succeeded.
 */
- (BOOL)zapTo:(NSObject<ServiceProtocol> *) service;

/*!
 @brief Start playback of given movie.
 
 @param movie Movie to start playback of.
 @return YES if starting playback succeeded.
 */
- (BOOL)playMovie:(NSObject<MovieProtocol> *) movie;

/*!
 @brief Delete a given Movie from Receiver HDD.
 
 @param movie Movie to delete.
 @return YES if deletion succeeded.
 */
- (BOOL)delMovie:(NSObject<MovieProtocol> *) movie;

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
- (BOOL)setVolume:(NSInteger) newVolume;

/*!
 @brief Schedule a Timer for recording on Receiver.
 
 @param newTimer Timer to add.
 @return YES if Timer was added successfully.
 */
- (BOOL)addTimer:(NSObject<TimerProtocol> *) newTimer;

/*!
 @brief Change existing Timer.
 
 @param oldTimer Existing Timer to change.
 @param newTimer New values for Timer.
 @return YES if Timer was changed successfully.
 */
- (BOOL)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer;

/*!
 @brief Remove a Timer on Receiver.
 
 @param oldTimer Timer to remove.
 @return YES if Timer was removed.
 */
- (BOOL)delTimer:(NSObject<TimerProtocol> *) oldTimer;

/*!
 @brief Send Remote Control Code to Receiver.
 
 @param type Button Code.
 @return YES if code was sent successfully.
 */
- (BOOL)sendButton:(NSInteger) type;

/*!
 @brief Send GUI Message to Receiver.
 
 @param message Message text.
 @param caption Message caption (not supported by all Connectors).
 @param type Message type (not supported by all Connectors).
 @param timeout Message timeout.
 @return YES if message was sent successfully.
 */
- (BOOL)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout;

/*!
 @brief Start instant Record on Receiver.
 
 @return YES if record was started.
 */
- (BOOL)instantRecord;



// Helper GUI
/*!
 @brief Returns upper bound for message types supported by Connector.
 
 @return Upper bound of message types.
 */
- (NSInteger)getMaxMessageType;

/*!
 @brief Textual representation of given message type.
 
 @param type Message type.
 @return Textual Representation.
 */
- (NSString *)getMessageTitle: (NSInteger)type;

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
