/*
 *  Constants.h
 *  dreaMote
 *
 *  Created by Moritz Venn on 09.03.08.
 *  Copyright 2008-2011 Moritz Venn. All rights reserved.
 *
 */

#import "DreamoteConfiguration.h"

// padding for margins
#define kLeftMargin				5
#define kTopMargin				5
#define kRightMargin			5
#define kBottomMargin			5
#define kTweenMargin			10

// control dimensions
#define kStdButtonWidth			106
#define kStdButtonHeight		40
#define kSegmentedControlHeight 40
#define kPageControlHeight		20
#define kPageControlWidth		160
#define kSliderHeight			7
#define kSwitchButtonWidth		94
#define kSwitchButtonHeight		27
#define kTextFieldHeight		([DreamoteConfiguration singleton].textFieldHeight)
#define kTextViewHeight			([DreamoteConfiguration singleton].textViewHeight)
#define kSearchBarHeight		40
#define kLabelHeight			20
#define kProgressIndicatorSize	40
#define kToolbarHeight			40
#define kUIProgressBarWidth		160
#define kUIProgressBarHeight	24
#define kWideButtonWidth		220
#define kMetadataDimensionPortrait	250
#define kMetadataDimensionLandscape	150

// specific font metrics used in our text fields and text views
#define kFontName				@"Arial"
#define kTextFieldFontSize		([DreamoteConfiguration singleton].textFieldFontSize)
#define kTextViewFontSize		([DreamoteConfiguration singleton].textViewFontSize)
#define kMultiEPGFontSize		([DreamoteConfiguration singleton].multiEpgFontSize)

// UITableView row heights
#define kUISmallRowHeight		([DreamoteConfiguration singleton].uiSmallRowHeight)
#define kUIRowHeight			([DreamoteConfiguration singleton].uiRowHeight)
#define kUIRowLabelHeight		([DreamoteConfiguration singleton].uiRowLabelHeight)
#define kEventCellHeight		([DreamoteConfiguration singleton].eventCellHeight)
#define kServiceCellHeight		([DreamoteConfiguration singleton].serviceCellHeight)
#define kServiceEventCellHeight	([DreamoteConfiguration singleton].serviceEventCellHeight)
#define kMetadataCellHeight		([DreamoteConfiguration singleton].metadataCellHeight)
#define kAutoTimerCellHeight	([DreamoteConfiguration singleton].autotimerCellHeight)
#define kPackageCellHeight		([DreamoteConfiguration singleton].packageCellHeight)

// MultiEPG heights
#define kMultiEPGHeaderHeightIpad	(40) // Size of Header of iPad (else cell height)
#define kMultiEPGCellHeight			(25) // iPhone/iPod Touch without Picon
#define kMultiEPGCellHeightIpad		(60) // iPad
#define kMultiEPGCellHeightPicon	(42) // iPhone/iPod Touch with Picon
#define kMultiEPGServiceWidth		((IS_IPAD()) ? 100 : 70)

// table view cell content offsets
#define kCellLeftOffset			8
#define kCellTopOffset			12

// various text sizes
#define kMainTextSize			([DreamoteConfiguration singleton].mainTextSize)
#define kMainDetailsSize		([DreamoteConfiguration singleton].mainDetailsSize)
#define kServiceTextSize		([DreamoteConfiguration singleton].serviceTextSize)
#define kServiceEventServiceSize ([DreamoteConfiguration singleton].serviceEventServiceSize)
#define kServiceEventEventSize	([DreamoteConfiguration singleton].serviceEventEventSize)
#define kEventNameTextSize		([DreamoteConfiguration singleton].eventNameTextSize)
#define kEventDetailsTextSize	([DreamoteConfiguration singleton].eventDetailsTextSize)
#define kTimerServiceTextSize	([DreamoteConfiguration singleton].timerServiceTextSize)
#define kTimerNameTextSize		([DreamoteConfiguration singleton].timerNameTextSize)
#define kTimerTimeTextSize		([DreamoteConfiguration singleton].timerTimeTextSize)
#define kDatePickerFontSize		([DreamoteConfiguration singleton].datePickerFontSize)
#define kAutoTimerNameTextSize	([DreamoteConfiguration singleton].autotimerNameTextSize)
#define kPackageNameTextSize	([DreamoteConfiguration singleton].packageNameTextSize)
#define kPackageVersionTextSize	([DreamoteConfiguration singleton].packageVersionTextSize)

// defaults
#define kDefaultTimeout			@"15"
#define kTimeout				[[NSUserDefaults standardUserDefaults] integerForKey:kTimeoutKey]
#define kSatFinderDefaultInterval @"5.0"
#define kSearchHistoryDefaultLength ((IS_IPAD()) ? @"12" : @"9")

//
#define kVanilla_ID				@"Vanilla_ID"

// custom notifications
#define kReadConnectionsNotification	@"dreaMoteDidReadConnections"
#define kReconnectNotification			@"dreaMoteDidReconnect"
#define kBouquetsChangedNotification	@"dreaMoteDidChangeBouquets" // currently only covers added bouquets
#define kThemeChangedNotification		@"dreaMoteDidChangeTheme"
#define kAdRemovalPurchased				@"dreaMoteDoDisableAds"

// paths for custom configuration files
#define kConfigPath @"~/Library/Preferences/com.ritzMo.dreaMote.Connections.plist"
#define kHistoryPath @"~/Library/Preferences/com.ritzMo.dreaMote.SearchHistory.plist"
#define kEPGCachePath @"~/Library/Preferences/com.ritzMo.dreaMote.EPGCache.sqlite"
extern const char *kPiconGlob;
#define kPiconPath @"../Documents/%@"
#define kPiconPathPng @"../Documents/%@.png"

// keys in connection dict
#define kRemoteName				@"remoteNameKey"
#define kRemoteHost				@"remoteHostKey"
#define kUsername				@"usernameKey"
#define kPassword				@"passwordKey"
#define kConnector				@"connectorKey"
#define kSingleBouquet			@"singleBouquetKey"
#define kPort					@"portKey"
#define kAdvancedRemote			@"advancedRemote"
#define kSSL					@"ssl"
#define kShowNowNext			@"showNowNext"
#define kHideOutdatedWarning	@"suppressOldVersion"
#define kLoginFailed			@"loginFailed" // optional entry on autodetection

// keys in nsuserdefaults
#define kActiveConnection		@"activeConnector"
#define kVibratingRC			@"vibrateInRC"
#define kMessageTimeout			@"messageTimeout"
#define kPrefersSimpleRemote	@"prefersSimpleRemote"
#define kDatabaseVersion		@"databaseVersion" // refers to the epg cache
#define kSimpleRcWasShown		@"simpleRcWasShown"
#define kLastLaunchedVersion	@"lastLaunchedVersion"
#define kMultiEPGInterval		@"multiEpgInterval"
#define kSortMoviesByTitle		@"sortingMoviesByTitle"
#define kTimeoutKey				@"timeout"
#define kSatFinderInterval		@"satFinderRefreshInterval"
#define kSearchHistoryLength	@"searchHistoryLength"
#define kSeparateEpgByDay		@"separateEpgByDay"
#define kSatFinderAudio			@"satFinderWithAudio"
#define kActiveTheme			@"activeTheme"
#define kZapModeDefault			@"defaultZapMode"

#define kCurrentDatabaseVersion 2

#define kBatchDispatchItemsCount 10

// shared e2 xml element names
extern const char *kEnigma2Servicereference;
#define kEnigma2ServicereferenceLength 19
extern const char *kEnigma2Servicename;
#define kEnigma2ServicenameLength 14
extern const char *kEnigma2Description;
#define kEnigma2DescriptionLength 14
extern const char *kEnigma2DescriptionExtended;
#define kEnigma2DescriptionExtendedLength 22
extern const char *kEnigma2Tags;
#define kEnigma2TagsLength 7
extern const char *kEnigma2Settings;
#define kEnigma2SettingsLength 15
extern const char *kEnigma2SettingName;
#define kEnigma2SettingNameLength 14
extern const char *kEnigma2SettingValue;
#define kEnigma2SettingValueLength 15
extern const char *kEnigma2Location;
#define kEnigma2LocationLength 11
extern const char *kEnigma2SimpleXmlItem;
#define kEnigma2SimpleXmlItemLength 16
extern const char *kEnigma2ServiceElement;
#define kEnigma2ServiceElementLength 10
extern const char *kEnigma2EventElement;
#define kEnigma2EventElementLength 8

// shared e1 xml element names
extern const char *kEnigmaDescription;
#define kEnigmaDescriptionLength 12
extern const char *kEnigmaDuration;
#define kEnigmaDurationLength 9
extern const char *kEnigmaBegin;
#define kEnigmaBeginLength 6
extern const char *kEnigmaReference;
#define kEnigmaReferenceLength 10
extern const char *kEnigmaName;
#define kEnigmaNameLength 5