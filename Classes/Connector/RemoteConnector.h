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
	kMaxConnector = 4, /*!< @brief Upper bound of connectors. */
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
	/*! @brief Can fetch a Screenshot of both (combined) GUI and video buffer. */
	kFeaturesCombinedScreenshot,
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
	/*!
	 @brief Similar EPG search.
	 @note This indicates that a native EPG search is possible and has
	 nothing to do with the emulated search in the full version.
	 */
	kFeaturesEPGSearchSimilar,
	/*!
	 @brief Knows repeated timers.
	 */
	kFeaturesTimerRepeated,
	/*!
	 @brief "Simple" Repeated timers
	 "Simple" means not complicated like "biweekly mondays and thursdays".

	 @note this is more of a hack to allow an implementation in enigma(2) without having
	 to bother about neutrino/svdrp :-)
	 */
	kFeaturesSimpleRepeated,
	/*!
	 @brief "Complicated" Repeated timers
	 Refers to Neutrino Timers.
	 */
	kFeaturesComplicatedRepeated,
	/*! @brief Allows to display currently playing service and event. */
	kFeaturesCurrent,
	/*! @brief Supports radio mode. */
	kFeaturesRadioMode,
	/*!
	 @brief Support recording locations and tags.
	 @note Tags are not reflected in the feature name because support for them was
	 added to dreamote later, but both were added to the web interface at the same time.
	 */
	kFeaturesRecordingLocations,
	/*! @brief Offers interface to a media player. */
	kFeaturesMediaPlayer,
	/*! @brief Can retrieve metadata from media player. */
	kFeaturesMediaPlayerMetadata,
	/*! @brief Can fetch files from receiver. */
	kFeaturesFileDownload,
	/*! @brief Can provide further information on the remote receiver. */
	kFeaturesAbout,
	/*!
	 @brief Allows to retrieve now/next through event-like interface.
	 @note I don't think this will be of any use outside of Enigma2, but who cares :-D
	 */
	kFeaturesNowNext,
	/*!
	 @brief Remote host allows to stream services.
	 @note Due to licensing issues I currently do not intend to incorporate a streaming
	 client directly, but this feature can also be used to show/hide buttons to defer the
	 request to an external app.
	 */
	kFeaturesStreaming,
	/*! @brief Timers have a title. */
	kFeaturesTimerTitle,
	/*! @brief Timer has a description */
	kFeaturesTimerDescription,
	/*! @brief Native timerlist cleanup functionality. */
	kFeaturesTimerCleanup,
	/*!
	 @brief Supports AutoTimer interface.
	 @note Probably will stay Enigma2 exclusive forever, but for the sake of having at least
	 kind of clean code, implement this properly.
	 */
	kFeaturesAutoTimer,
	/*!
	 @brief Supports EPGRefresh interface.
	 @note Probably will stay Enigma2 exclusive forever, but for the sake of having at least
	 kind of clean code, implement this properly.
	 */
	kFeaturesEPGRefresh,
	/*! @brief Sleep-Timer interface. */
	kFeaturesSleepTimer,
	/*!
	 @brief Extended Playlist Handling in MediaPlayer.
	 @note This refers to save (partially broken)/clear/shuffle.
	 */
	kFeaturesMediaPlayerPlaylistHandling,
	/*!
	 @brief Improved Playlist Handling in MediaPlayer.
	 @note Proper load and save support.
	 */
	kFeaturesMediaPlayerPlaylistLoad,
	/*!
	 @brief Package management present.
	 */
	kFeaturesPackageManagement,
	/*!
	 @brief Viable Service Editor interface.
	 */
	kFeaturesServiceEditor,
	/*!
	 @brief Get dedicated provider list.
	 */
	kFeaturesProviderList,
	/*!
	 @brief Allows to retrieve now/next through event-like interface in a single call.
	 */
	kFeaturesOptimizedNowNext,
	/*!
	 @brief Recordings can be moved between folders. Requires kFeaturesRecordingLocations.
	 */
	kFeaturesMovingRecordings,
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
	kButtonCodePlayPause = 207,
	kButtonCodeFFwd = 163,
	kButtonCodeFRwd = 165,
	kButtonCodeStop = 128,
};

/*!
 @brief List types for package management
 */
enum packageManagementList
{
	kPackageListRegular,
	kPackageListInstalled,
	kPackageListUpgradable,
};

// Forward declarations...
@class AutoTimer;
@class BaseXMLReader;
@class EPGRefreshSettings;
@class Result;
@class SleepTimer;
@protocol EventProtocol;
@protocol MovieProtocol;
@protocol ServiceProtocol;
@protocol TimerProtocol;
@protocol FileProtocol;
@protocol AboutSourceDelegate;
@protocol AutoTimerSourceDelegate;
@protocol EPGRefreshSettingsSourceDelegate;
@protocol EventSourceDelegate;
@protocol LocationSourceDelegate;
@protocol MediaPlayerShuffleDelegate;
@protocol MetadataSourceDelegate;
@protocol MovieSourceDelegate;
@protocol NowSourceDelegate;
@protocol NextSourceDelegate;
@protocol ServiceSourceDelegate;
@protocol SignalSourceDelegate;
@protocol SleepTimerSourceDelegate;
@protocol TagSourceDelegate;
@protocol TimerSourceDelegate;
@protocol VolumeSourceDelegate;
@protocol FileSourceDelegate;



/*!
 @brief Protocol of Connectors.

 Every Connector has to implement this Protocol which allows us to interact with
 same through a Standard API.
 */
@protocol RemoteConnector

#pragma mark -
#pragma mark General functions
#pragma mark -

/*!
 @brief Standard constructor for RemoteConnectors.

 @param connection Dictionary describing connection.
 @return RemoteConnector Object.
 */
+ (NSObject <RemoteConnector>*)newWithConnection:(const NSDictionary *)connection;

/*!
 @brief Return default connection data known for this connector.

 @return NSArray containint dictonaries describing connection data.
 */
+ (NSArray *)knownDefaultConnections;

/*!
 @brief Checks which given NSNetServices could be connected.
 @note No need to filter out default connections.

 @param netServices
 return Connection Dictionaries.
 */
+ (NSArray *)matchNetServices:(NSArray *)netServices;

/*!
 @brief Free Caches used by Backend.
 @note This function is used by some Backends to free Ressources that are
 cached during Runtime and freed when running low on memory.
 */
- (void)freeCaches;

/*!
 @brief Returns upper bound for message types supported by Connector.

 @return Upper bound of message types.
 */
- (const NSUInteger const)getMaxMessageType;

/*!
 @brief Returns upper bound of Volume setting.

 @return Upper bound of Volume.
 */
- (const NSUInteger const)getMaxVolume;

/*!
 @brief Textual representation of given message type.

 @param type Message type.
 @return Textual Representation.
 */
- (NSString *)getMessageTitle: (NSUInteger)type;

/*!
 @brief Check if a Connector supports a given Feature.

 @param feature Feature to check for.
 @return YES if this Feature is supported.
 */
- (const BOOL const)hasFeature: (enum connectorFeatures)feature;

/*!
 @brief Returns whether to Receiver is currently reachable or not.
 @note This Function is also used by the Autodetection.

 @param error Pointer to pointer of NSError object. Can give additional information regardless of return value.
 @return YES if the Receiver is reachable and verified as compatible with the Connector.
 */
- (BOOL)isReachable:(NSError **)error;

/*!
 @brief Create instance of RC Emulator.

 @return instance of rc emulator.
 */
- (UIViewController *)newRCEmulator;

#pragma mark -
#pragma mark Services / EPG
#pragma mark -

/*!
 @brief Fetch list of available Bouquets.

 @param delegate Delegate to be called back.
 @param isRadio Fetch radio bouquets?
 @return Pointer to newly created XMLReader.
 */
- (BaseXMLReader *)fetchBouquets: (NSObject<ServiceSourceDelegate> *)delegate isRadio:(BOOL)isRadio;

/*!
 @brief Fetch list of available Providers.

 @param delegate Delegate to be called back.
 @param isRadio Fetch radio providers?
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesProviderList
- (BaseXMLReader *)fetchProviders:(NSObject<ServiceSourceDelegate> *)delegate isRadio:(BOOL)isRadio;
/*!
 @brief Return service describing the 'All Services'-Bouquet.

 @param isRadio Fetch radio bouquet?
 @return Service object.
 */
@optional // kFeaturesProviderList
- (NSObject<ServiceProtocol> *)allServicesBouquet:(BOOL)isRadio;

/*!
 @brief Request EPG of given Service from Receiver.

 @param delegate Delegate to be called back.
 @param service Service to fetch EPG of.
 @return Pointer to newly created XMLReader.
 */
@required
- (BaseXMLReader *)fetchEPG: (NSObject<EventSourceDelegate> *)delegate service:(NSObject<ServiceProtocol> *)service;

/*!
 @brief Fetch Services of a given Bouquet.
 @note If no bouquet is given the Connector can choose to return the default bouquet.

 @param delegate Delegate to be called back.
 @param bouquet Bouquet to request Services of.
 @param isRadio Fetch radio services?
 @return Pointer to newly created XMLReader.
 */
- (BaseXMLReader *)fetchServices: (NSObject<ServiceSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio;

/*!
 @brief Request list of current and upcoming event from the receiver.

 @param delegate Delegate to be called back.
 @param bouquet Bouquet to request events of.
 @param isRadio Fetch radio services?
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesOptimizedNowNext
- (BaseXMLReader *)getNowNext:(NSObject<NowSourceDelegate, NextSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio;

/*!
 @brief Request bouquet list by upcoming event from the receiver.

 @param delegate Delegate to be called back.
 @param bouquet Bouquet to request upcoming events of.
 @param isRadio Fetch radio services?
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesNowNext
- (BaseXMLReader *)getNext:(NSObject<NextSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio;

/*!
 @brief Request bouquet list by currently playing event from the receiver.

 @param delegate Delegate to be called back.
 @param bouquet Bouquet to request currently playing events from.
 @param isRadio Fetch radio services?
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesNowNext
- (BaseXMLReader *)getNow:(NSObject<NowSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio;

/*!
 @brief Request stream URL for given service.

 @param service Service to stream.
 @return Stream URL.
 */
@optional // kFeaturesStreaming
- (NSURL *)getStreamURLForService:(NSObject<ServiceProtocol> *)service;

/*!
 @brief Invoke an EPG Search for Title.
 @note The Search is currently hardcoded to a case-insensitive search in ISO8859-15.

 @param delegate Delegate to be called back.
 @param title Text to Search in Event Titles.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesEPGSearch
- (BaseXMLReader *)searchEPG: (NSObject<EventSourceDelegate> *)delegate title:(NSString *)title;

/*!
 @brief Search EPG for Similar Events.
 @note Currently this needs support on the Receiver and therefore is only supported
 on Enigma2.

 @param delegate Delegate to be called back.
 @param event Event to search similar events of.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesEPGSearchSimilar
- (BaseXMLReader *)searchEPGSimilar: (NSObject<EventSourceDelegate> *)delegate event:(NSObject<EventProtocol> *)event;

/*!
 @brief Zap to given service.

 @param service Service to zap to.
 @return YES if zapping succeeded.
 */
@required
- (Result *)zapTo:(NSObject<ServiceProtocol> *) service;

#pragma mark -
#pragma mark Timers
#pragma mark -

/*!
 @brief Schedule a Timer for recording on Receiver.

 @param newTimer Timer to add.
 @return YES if Timer was added successfully.
 */
- (Result *)addTimer:(NSObject<TimerProtocol> *) newTimer;

/*!
 @brief Cleanup timer list.

 @note List of timers must be provided if no native cleanup functionality is
 available, otherwise the parameter is ignored.
 @param timers List of timers to remove if cleanup is not available natively.
 @return YES if timers were removed.
 */
- (Result *)cleanupTimers:(const NSArray *)timers;

/*!
 @brief Remove a Timer on Receiver.

 @param oldTimer Timer to remove.
 @return YES if Timer was removed.
 */
- (Result *)delTimer:(NSObject<TimerProtocol> *) oldTimer;

/*!
 @brief Change existing Timer.

 @param oldTimer Existing Timer to change.
 @param newTimer New values for Timer.
 @return YES if Timer was changed successfully.
 */
- (Result *)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer;

/*!
 @brief Request Timerlist from the Receiver.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
- (BaseXMLReader *)fetchTimers: (NSObject<TimerSourceDelegate> *)delegate;

/*!
 @brief Request list of all available Tags from the Receiver.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesRecordingLocations
- (BaseXMLReader *)fetchTags:(NSObject<TagSourceDelegate> *)delegate;

#pragma mark -
#pragma mark Recordings
#pragma mark -

/*!
 @brief Delete a given Movie from Receiver HDD.

 @param movie Movie to delete.
 @return YES if deletion succeeded.
 */
@optional // kFeaturesRecordDelete
- (Result *)delMovie:(NSObject<MovieProtocol> *) movie;

/*!
 @brief Move a given Movie on Receiver HDD.

 @param movie Movie to move.
 @param location Directory to move movie to.
 @return Valid result if recording was moved, invalid one with given reason otherwise.
 */
@optional // kFeaturesMovingRecordings
- (Result *)moveMovie:(NSObject<MovieProtocol> *)movie toLocation:(NSString *)location;

/*!
 @brief Request Recording Locations from the Receiver.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesRecordingLocations
- (BaseXMLReader *)fetchLocationlist: (NSObject<LocationSourceDelegate> *)delegate;

/*!
 @brief Add a new location.

 @param fullpath Path of the location.
 @param createFolder Create the folder if it does not exist?
 @return Valid result if location was added, invalid one and reason otherwise.
 */
@optional // kFeaturesRecordingLocations
- (Result *)addLocation:(NSString *)fullpath createFolder:(BOOL)createFolder;

/*!
 @brief Remove an existing location (bookmark).
 
 @param fullpath Bookmark to remove.
 @return Valid result if location was removed, invalid one and reason otherwise.
 */
@optional // kFeaturesRecordingLocations
- (Result *)delLocation:(NSString *)fullpath;

/*!
 @brief Request Movielist from the Receiver.

 @param delegate Delegate to be called back.
 @param location Directory to search for movies
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesRecordInfo
- (BaseXMLReader *)fetchMovielist: (NSObject<MovieSourceDelegate> *)delegate withLocation:(NSString *)location;

/*!
 @brief Request stream URL for given movie.

 @param movie Movie to stream.
 @return Stream URL.
 */
@optional // kFeaturesStreaming
- (NSURL *)getStreamURLForMovie:(NSObject<MovieProtocol> *)movie;

/*!
 @brief Start instant Record on Receiver.

 @return YES if record was started.
 */
@optional // kFeaturesInstantRecord
- (Result *)instantRecord;

/*!
 @brief Start playback of given movie.

 @param movie Movie to start playback of.
 @return YES if starting playback succeeded.
 */
@optional // kFeaturesRecordInfo
- (Result *)playMovie:(NSObject<MovieProtocol> *) movie;

#pragma mark -
#pragma mark MediaPlayer
#pragma mark -

/*!
 @brief Add a given track to playlist.

 @param fullpath Path to the track.
 @param play Start playing the track?
 @return YES if track was added successfully and (eventually) playback was started.
 */
@optional // kFeaturesMediaPlayer
- (Result *)addTrack:(NSObject<FileProtocol> *) track startPlayback:(BOOL)play;

/*!
 @brief Request filelist from the receiver.

 @param delegate Delegate to be called back.
 @param path Directory to be searched for files.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesMediaPlayer
- (BaseXMLReader *)fetchFiles: (NSObject<FileSourceDelegate> *)delegate path:(NSString *)path;

/*!
 @brief Request playlist from the receiver.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesMediaPlayer
- (BaseXMLReader *)fetchPlaylist: (NSObject<FileSourceDelegate> *)delegate;

/*!
 @brief Request a file from the Receiver.

 @param type Full path to file.
 @return Pointer to file or nil on failure.
 */
@optional // kFeaturesFileDownload
- (NSData *)getFile: (NSString *)fullpath;

/*!
 @brief Request metadata of currently played track from the receiver.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesMediaPlayerMetadata
- (BaseXMLReader *)getMetadata: (NSObject<MetadataSourceDelegate> *)delegate;

/*!
 @brief Send command to MediaPlayer.

 @param command Textual representation of command.
 @return YES if command was sent successfully.
 */
@optional // kFeaturesMediaPlayer
- (Result *)mediaplayerCommand:(NSString *)command;

/*!
 @brief Play a given track.

 @param fullpath Path to the track.
 @return YES if starting playback succeeded.
 */
@optional // kFeaturesMediaPlayer
- (Result *)playTrack:(NSObject<FileProtocol> *) track;

/*!
 @brief Remove a given track from playlist.

 @param fullpath Path to the track.
 @return YES if track was removed successfully.
 */
@optional // kFeaturesMediaPlayer
- (Result *)removeTrack:(NSObject<FileProtocol> *) track;

/*!
 @brief Shuffle playlist.
 @note The playlist array will be changed.

 @param delegate Delegate to be called back.
 @param playlist Items currently in playlist.
 */
@optional // kFeaturesMediaPlayer
- (void)shufflePlaylist:(NSObject<MediaPlayerShuffleDelegate> *)delegate playlist:(NSMutableArray *)playlist;

/*!
 @brief Save playlist to remote file.

 @param filename Filename without extension of the playlist.
 @return YES if playlist was saved successfully.
 */
@optional // kFeaturesMediaPlayerPlaylistHandling
- (Result *)savePlaylist:(NSString *)filename;

/*!
 @brief Load playlist from remote file.
 @note Playlist has to be in /etc/enigma2/playlist

 @param filename Filename without extension of the playlist.
 @return YES if playlist was loaded successfully.
 */
@optional // kFeaturesMediaPlayerPlaylistHandling
- (Result *)loadPlaylist:(NSObject<FileProtocol> *)file;

#pragma mark -
#pragma mark AutoTimer
#pragma mark -
#if IS_FULL()

/*!
 @brief Run forced parsing of EPG.

 @return Result text returned by remote host.
 */
@optional // kFeaturesAutoTimer
- (Result *)parseAutoTimer;

/*!
 @brief Retrieve List of AutoTimers.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesAutoTimer
- (BaseXMLReader *)fetchAutoTimers:(NSObject<AutoTimerSourceDelegate> *)delegate;

/*!
 @brief Add new AutoTimer.

 @param newTimer AutoTimer to add.
 @return Valid Result if AutoTimer was added successfully.
 */
@optional // kFeaturesAutoTimer
- (Result *)addAutoTimer:(AutoTimer *)newTimer;

/*!
 @brief Remove an AutoTimer from Receiver.

 @param oldTimer AutoTimer to remove.
 @return Valid Result if Timer was removed.
 */
@optional // kFeaturesAutoTimer
- (Result *)delAutoTimer:(AutoTimer *)oldTimer;

/*!
 @brief Change existing AutoTimer.

 @param changeTimer AutoTimer to change.
 @return Valid Result if Timer was changed successfully.
 */
@optional // kFeaturesAutoTimer
- (Result *)editAutoTimer:(AutoTimer *)changeTimer;
#endif

#pragma mark -
#pragma mark EPGRefresh
#pragma mark -

/*!
 @brief Retrieve EPGRefresh settings.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesEPGRefresh
- (BaseXMLReader *)getEPGRefreshSettings:(NSObject<EPGRefreshSettingsSourceDelegate> *)delegate;

/*!
 @brief Retrieve EPGRefresh services.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesEPGRefresh
- (BaseXMLReader *)getEPGRefreshServices:(NSObject<ServiceSourceDelegate> *)delegate;

/*!
 @brief Commit changes in EPGRefresh settings to receiver.

 @param settings Settings.
 @param services Services.
 @param bouquets Bouquets.
 @return Valid Result if settings were changed.
 */
@optional // kFeaturesEPGRefresh
- (Result *)setEPGRefreshSettings:(EPGRefreshSettings *)settings andServices:(NSArray *)services andBouquets:(NSArray *)bouquets;

/*!
 @brief Initiate manual EPG refresh.

 @return Valid Result on success, else invalid one with error message.
 */
@optional // kFeaturesEPGRefresh
- (Result *)startEPGRefresh;

#pragma mark -
#pragma mark Sleeptimer
#pragma mark -

/*!
 @brief Retrieve SleepTimer settings.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesSleepTimer
- (BaseXMLReader *)getSleepTimerSettings:(NSObject<SleepTimerSourceDelegate> *)delegate;

/*!
 @brief Set SleepTimer settings.
 @note Will call back delegate with new settings.

 @param settings New settings.
 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesSleepTimer
- (BaseXMLReader *)setSleepTimerSettings:(SleepTimer *)settings delegate:(NSObject<SleepTimerSourceDelegate> *)delegate;

#pragma mark -
#pragma mark Package Management
#pragma mark -

/*!
 @brief Update package list on remote host.
 */
@optional // kFeaturesPackageManagement
- (void)packageManagementUpdate;

/*!
 @brief Retrieve list of packages from remote host.

 @param listType Type of list to retrieve
 @return Array of packages in requested list.
 */
@optional // kFeaturesPackageManagement
- (NSArray *)packageManagementList:(enum packageManagementList)listType;

/*!
 @brief Do upgrades.
 */
@optional // kFeaturesPackageManagement
- (void)packageManagementUpgrade;

/*!
 @brief Commit changes to package management.

 @note This will automatically install not-installed packages and remove installed ones.
 @param packages List of packages that are supposed to be changes.
 */
@optional // kFeaturesPackageManagement
- (void)packageManagementCommit:(NSArray *)packages;

#pragma mark -
#pragma mark ServiceEditor
#pragma mark -

/*!
 @brief Add a new bouquet with given name.
 @param name
 @param isRadio Work with radio boquets?
 @return
 */
@optional // kFeaturesServiceEditor
- (Result *)serviceEditorAddBouquet:(NSString *)name isRadio:(BOOL)isRadio;

/*!
 @brief Remove a given bouquet.
 @param bouquet
 @param isRadio Work with radio boquets?
 @return
 */
@optional // kFeaturesServiceEditor
- (Result *)serviceEditorRemoveBouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio;

/*!
 @brief Move bouquet to another position.
 @param bouquet 
 @param position
 @param isRadio Work with radio boquets?
 @return
 */
@optional // kFeaturesServiceEditor
- (Result *)serviceEditorMoveBouquet:(NSObject<ServiceProtocol> *)bouquet toPosition:(NSInteger)position isRadio:(BOOL)isRadio;

/*!
 @brief Move service to another position in given bouquet.
 @param service 
 @param position
 @param bouquet 
 @param isRadio Work with radio boquets?
 @return
 */
@optional // kFeaturesServiceEditor
- (Result *)serviceEditorMoveService:(NSObject<ServiceProtocol> *)service toPosition:(NSInteger)position inBouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio;

/*!
 @brief
 @param bouquet
 @param name
 @param isRadio Work with radio boquets?
 @return
 */
@optional // kFeaturesServiceEditor
- (Result *)serviceEditorRenameBouquet:(NSObject<ServiceProtocol> *)bouquet name:(NSString *)name isRadio:(BOOL)isRadio;

/*!
 @brief
 @param service
 @param name
 @param bouquet
 @param before
 @param isRadio Work with radio boquets?
 @return
 */
@optional // kFeaturesServiceEditor
- (Result *)serviceEditorRenameService:(NSObject<ServiceProtocol> *)service name:(NSString *)name inBouquet:(NSObject<ServiceProtocol> *)bouquet beforeService:(NSObject<ServiceProtocol> *)before isRadio:(BOOL)isRadio;

/*!
 @brief Add service to a bouquet.
 @param service Service to add.
 @param targetBouquet Bouquet to add this service to (or alternative service, or regular service which then becomes an alternative service).
 @param parentBouquet If adding alternative parent bouquet, else nil.
 @param isRadio If adding alternative mode of parent bouquet, else nil.
 @note Can be used to add services to an alternative, just use the alternative service as bouquet.
 @note If using with alternative services and the service is not yet an alternative, it will be changed to an alternative service and the
       service list should be reloaded.
 @return Results of this operation.
 */
@optional // kFeaturesServiceEditor
- (Result *)serviceEditorAddService:(NSObject<ServiceProtocol> *)service toBouquet:(NSObject<ServiceProtocol> *)targetBouquet inBouquet:(NSObject<ServiceProtocol> *)parentBouquet isRadio:(BOOL)isRadio;

/*!
 @brief
 @param service
 @param bouquet
 @param isRadio Work with radio boquets?
 @note Can be used to remove services from an alternative, just use the alternative service as bouquet.
 @return
 */
@optional // kFeaturesServiceEditor
- (Result *)serviceEditorRemoveService:(NSObject<ServiceProtocol> *)service fromBouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio;

/*!
 @brief
 @param service
 @param bouquet
 @param isRadio Work with radio boquets?
 @return
 */
@optional // kFeaturesServiceEditor
- (Result *)serviceEditorRemoveAlternatives:(NSObject<ServiceProtocol> *)service inBouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio;

/*!
 @brief
 @param name
 @param service
 @param bouquet
 @param isRadio Work with radio boquets?
 @return
 */
@optional // kFeaturesServiceEditor
- (Result *)serviceEditorAddMarker:(NSString *)name beforeService:(NSObject<ServiceProtocol> *)service inBouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio;

#pragma mark -
#pragma mark Control
#pragma mark -

/*!
 @brief Get information on receiver.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesAbout
- (BaseXMLReader *)getAbout: (NSObject<AboutSourceDelegate> *)delegate;

/*!
 @brief Get information on currently playing service and now/new event.

 @param delegate Delegate to be called back.
 @return Pointer to newly created XMLReader.
 */
@optional // kFeaturesCurrent
- (BaseXMLReader *)getCurrent: (NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate;

/*!
 @brief Request a Screnshot from the Receiver.

 @param type Requested Screenshot type.
 @return Pointer to Screenshot or nil on failure.
 */
@optional // kFeaturesScreenshot
- (NSData *)getScreenshot: (enum screenshotType)type;

/*!
 @brief Get current Signal Strength.

 @param delegate Delegate to be called back.
 */
@optional // kFeaturesSatFinder
- (void)getSignal: (NSObject<SignalSourceDelegate> *)delegate;

/*!
 @brief Get current Volume settings.

 @param delegate Delegate to be called back.
 */
@required
- (void)getVolume: (NSObject<VolumeSourceDelegate> *)delegate;

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
 @brief Set Volume to new level.

 @param newVolume Volume level to set.
 @return YES if change succeeded.
 */
- (Result *)setVolume:(NSInteger) newVolume;

/*!
 @brief Toggle Muted status on Receiver.

 @return YES if audio is muted at the end of this function.
 */
- (BOOL)toggleMuted;

#pragma mark Powerstate

/*!
 @brief Invoke Reboot of Receiver.
 */
- (void)reboot;

/*!
 @brief Invoke GUI Restart of Receiver.
 */
@optional // kFeaturesGUIRestart
- (void)restart;

/*!
 @brief Invoke Shutdown procedure of Receiver.
 */
@required
- (void)shutdown;

/*!
 @brief Invoke Standby of Receiver.
 */
- (void)standby;

@end
