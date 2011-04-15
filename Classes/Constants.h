/*
 *  Constants.h
 *  dreaMote
 *
 *  Created by Moritz Venn on 09.03.08.
 *  Copyright 2008-2011 Moritz Venn. All rights reserved.
 *
 */

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
#define kTextFieldHeight		((IS_IPAD()) ? 35 : 30)
#define kTextViewHeight			((IS_IPAD()) ? 300 : 220)
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
#define kTextFieldFontSize		((IS_IPAD()) ? 22 : 18)
#define kTextViewFontSize		((IS_IPAD()) ? 22 : 18)
#define kMultiEPGFontSize		((IS_IPAD()) ? 16 : 10)

// UITableView row heights
#define kUISmallRowHeight		((IS_IPAD()) ? 43 : 38)
#define kUIRowHeight			((IS_IPAD()) ? 55 : 50)
#define kUIRowLabelHeight		22
#define kEventCellHeight		((IS_IPAD()) ? 50 : 48)
#define kServiceCellHeight		38
#define kServiceEventCellHeight	((IS_IPAD()) ? 60 : 50)
#define kMetadataCellHeight		275
#define kMultiEPGCellHeight		((IS_IPAD()) ? 60 : 25)
#define kAutoTimerCellHeight	38

// table view cell content offsets
#define kCellLeftOffset			8
#define kCellTopOffset			12

// various text sizes
#define kMainTextSize			((IS_IPAD()) ? 22 : 18)
#define kMainDetailsSize		((IS_IPAD()) ? 20 : 14)
#define kServiceTextSize		((IS_IPAD()) ? 20 : 16)
#define kServiceEventServiceSize ((IS_IPAD()) ? 18 : 14)
#define kServiceEventEventSize	((IS_IPAD()) ? 15 : 12)
#define kEventNameTextSize		((IS_IPAD()) ? 18 : 14)
#define kEventDetailsTextSize	((IS_IPAD()) ? 15 : 12)
#define kTimerServiceTextSize	((IS_IPAD()) ? 20 : 14)
#define kTimerNameTextSize		((IS_IPAD()) ? 15 : 12)
#define kTimerTimeTextSize		((IS_IPAD()) ? 15 : 12)
#define kDatePickerFontSize		((IS_IPAD()) ? 26 : 14)
#define kAutoTimerNameTextSize	((IS_IPAD()) ? 20 : 16)

// timeout
#define kDefaultTimeout			@"15"
#define kTimeout				[[NSUserDefaults standardUserDefaults] integerForKey:kTimeoutKey]

//
#define kVanilla_ID				@"Vanilla_ID"

// custom notifications
#define kReadConnectionsNotification	@"dreaMoteDidReadConnections"
#define kReconnectNotification			@"dreaMoteDidReconnect"

// paths for custom configuration files
#define kConfigPath @"~/Library/Preferences/com.ritzMo.dreaMote.Connections.plist"
#define kHistoryPath @"~/Library/Preferences/com.ritzMo.dreaMote.SearchHistory.plist"
#define kEPGCachePath @"~/Library/Preferences/com.ritzMo.dreaMote.EPGCache.sqlite"
#define kPiconPath @"../Documents/%@.png"

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

#define kCurrentDatabaseVersion 2

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
extern const char *kEnigma2LocationLength;
#define kEnigma2SettingNameLength 14
extern const char *kEnigma2SettingName;
#define kEnigma2SettingValueLength 15
extern const char *kEnigma2SettingValue;
