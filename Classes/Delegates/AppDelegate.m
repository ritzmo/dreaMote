//
//  AppDelegate.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import <glob.h>
#include <fcntl.h>
#import "LiteUnzip.h"

#import <AudioToolbox/AudioToolbox.h>

#import "NSArray+ArrayFromData.h"
#import "NSData+Base64.h"
#import "NSDateFormatter+FuzzyFormatting.h"
#import "UIDevice+SystemVersion.h"

#import "Appirater.h"
#import "BWQuincyManager.h"
#import <Connector/RemoteConnectorObject.h>

// ShareKit
#import "SHKConfiguration.h"
#import "SHKFacebook.h"
#import <Configuration/DreamoteSHKConfigurator.h>

// zap config
#import <ListController/ServiceZapListController.h>

#if IS_FULL()
	#import <EPGCache/EPGCache.h>
#endif

#import "SFHFKeychainUtils.h"

#import "MBProgressHUD.h"

// SSKTk
#import "SSKManager.h"

enum appDelegateAlertTags
{
	TAG_NONE = 0,
	TAG_URL = 1,
	TAG_ZIP = 2,
};

static const char *basename(const char *path)
{
	const char *base = path;
	const char *name = NULL;
	for(name = base; *name; ++name)
	{
		if(*name == '/')
			base = name + 1;
	}
	return base;
}

void ToneInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
#if IS_DEBUG()
	NSLog(@"[AppDelegate] ToneInterruptionListener called. Anything to do?");
#endif
}

@interface AppDelegate(Picons)
/*!
 @brief Check if Picons zip exists and ask to unpack if true.
 @return YES if picons were found, otherwise NO.
 */
- (BOOL)checkForPicons;

/*!
 @brief Unpacks the zip file kept as cachedFilename.
 */
- (void)unpackPicons;
@end

@implementation AppDelegate

@synthesize window;
@synthesize tabBarController;

- (id)init
{
	if((self = [super init]))
	{
		wasSleeping = NO;
		cachedURL = nil;
		welcomeType = welcomeTypeNone;
	}
	return self;
}

- (BOOL)isBusy
{
	return cachedURL != nil;
}

- (welcomeTypes)welcomeType
{
	welcomeTypes returnValue = welcomeType;
	welcomeType = welcomeTypeNone;
	return returnValue;
}

- (NSString *)uuid
{
	NSError *error = nil;
	NSString *object = [SFHFKeychainUtils getPasswordForUsername:@"uniqueID"
												  andServiceName:@"freaqueUuid"
														   error:&error];
	if(error || !object || [object isEqualToString:@""])
	{
		CFUUIDRef cfUuidRef = CFUUIDCreate(kCFAllocatorDefault);
		CFStringRef cfUuid = CFUUIDCreateString(kCFAllocatorDefault, cfUuidRef);
		object = [(__bridge NSString *)cfUuid copy];
		CFRelease(cfUuid);
		CFRelease(cfUuidRef);
		[SFHFKeychainUtils storeUsername:@"uniqueID"
							 andPassword:object
						  forServiceName:@"freaqueUuid"
						  updateExisting:YES
								   error:&error];
		if(error)
			NSLog(@"failed to store uuid");
	}
	return object;
}

#pragma mark -
#pragma mark UIApplicationDelegate
#pragma mark -

/* finished launching */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !IS_DEBUG()
	[[BWQuincyManager sharedQuincyManager] setSubmissionURL:@"http://ritzmo.de/iphone/quincy/crash_v200.php"];
#endif

	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber *activeConnectionId = [NSNumber numberWithInteger: 0];
	NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
	NSNumber *multiEPGdefaultInterval = [NSNumber numberWithInteger:60*60*2];
	NSString *testValue = nil;

	NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"NO", kVibratingRC,
								 @"10", kMessageTimeout,
								 @"YES", kPrefersSimpleRemote,
								 multiEPGdefaultInterval, kMultiEPGInterval,
								 @"NO", kSortMoviesByTitle,
								 kDefaultTimeout, kTimeoutKey,
								 kSatFinderDefaultInterval, kSatFinderInterval,
								 kSearchHistoryDefaultLength, kSearchHistoryLength,
								 @"NO", kSeparateEpgByDay,
								 [NSNumber numberWithInteger:zapActionMax], kZapModeDefault,
								 nil];
	[stdDefaults registerDefaults:appDefaults];

	// load theme
	[DreamoteConfiguration singleton].currentTheme = [stdDefaults integerForKey:kActiveTheme];

	// not configured at all
	if((testValue = [stdDefaults stringForKey: kActiveConnection]) == nil)
	{
		NSString *databaseVersion = [NSString stringWithFormat:@"%d", kCurrentDatabaseVersion];

		// settings of previous versions might not have been saved correctly, so try to delete old database
		NSInteger integerVersion = -1;
		if((testValue = [stdDefaults stringForKey: kDatabaseVersion]) != nil) // 1.0.1+
		{
			integerVersion = [testValue integerValue];
		}
		if(integerVersion < kCurrentDatabaseVersion)
		{
			const NSFileManager *fileManager = [NSFileManager defaultManager];
			NSString *databasePath = [kEPGCachePath stringByExpandingTildeInPath];
			if([fileManager fileExistsAtPath:databasePath])
			{
				[fileManager removeItemAtPath:databasePath error:nil];
			}
		}

		// write some settings to disk
		[stdDefaults setObject:activeConnectionId forKey:kActiveConnection];
		[stdDefaults setObject:databaseVersion forKey:kDatabaseVersion];
		[stdDefaults setObject:currentVersion forKey:kLastLaunchedVersion];
		[stdDefaults synchronize];

		welcomeType = welcomeTypeFull;
	}
	// 1.0+ configuration
	else
	{
		activeConnectionId = [NSNumber numberWithInteger:[testValue integerValue]];

		NSInteger integerVersion = -1;
		if((testValue = [stdDefaults stringForKey: kDatabaseVersion]) != nil) // 1.0.1+
		{
			integerVersion = [testValue integerValue];
		}
		// delete database if it exists and has older (or no) version
		if(integerVersion < kCurrentDatabaseVersion)
		{
			const NSFileManager *fileManager = [NSFileManager defaultManager];
			NSString *databasePath = [kEPGCachePath stringByExpandingTildeInPath];
			if([fileManager fileExistsAtPath:databasePath])
			{
				[fileManager removeItemAtPath:databasePath error:nil];
			}

			// new database will be created automatically, so bump version here
			NSString *databaseVersion = [NSString stringWithFormat:@"%d", kCurrentDatabaseVersion];
			[stdDefaults setValue:databaseVersion forKey:kDatabaseVersion];
		}

		/*!
		 @brief Determine whether or not to display welcome screen

		 Since the screen was not present before 1.0.2, we show it in full for any version before it.
		 In subsequent versions we will only show changes in the current version.
		 */
		if((testValue = [stdDefaults stringForKey:kLastLaunchedVersion]) != nil) // 1.0.2+
		{
			if(![testValue isEqualToString:currentVersion])
				welcomeType = welcomeTypeChanges;
		}
		else
			welcomeType = welcomeTypeFull;

		if(welcomeType != welcomeTypeNone)
		{
			[stdDefaults setValue:currentVersion forKey:kLastLaunchedVersion];
			[stdDefaults synchronize];
		}
	}

	BOOL treatAsFirst = YES;
	if([RemoteConnectorObject loadConnections])
	{
		treatAsFirst = ![RemoteConnectorObject connectTo:[activeConnectionId integerValue] inBackground:YES];

		// by using mg split view loadView is called too early which might lead to the
		// wrong mode being shown (e.g. only movie list & movie view for enigma2 instead
		// of location list & movie list). posting this notification will trigger the necessary
		// reload.
		[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
	}
	// no configured connections or no host to connect to, show help and start bonjour search
	if(treatAsFirst)
	{
		welcomeType = welcomeTypeFull;
		// NOTE: this will run until the app quits or the user enters and leaves the configuration, but let's ignore this for now.
		[RemoteConnectorObject start];
	}

	// Show the window and view
	[window addSubview: tabBarController.view];
	[window makeKeyAndVisible];

	// don't prompt for rating if zip file is found to avoid (possibly) showing two alerts
	BOOL promptForRating = YES;

	// check for .zip files possibly containing picons
	if([self checkForPicons])
	{
		promptForRating = NO;
	}
	[Appirater appLaunched:promptForRating];

	DreamoteSHKConfigurator *configurator = [[DreamoteSHKConfigurator alloc] init];
	[SHKConfiguration sharedInstanceWithConfigurator:configurator];

	// initialize audio session
	OSStatus result = AudioSessionInitialize(NULL, NULL, ToneInterruptionListener, (__bridge void *)(self));
	if (result == kAudioSessionNoError)
	{
		UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
	}

	// initialize IAP code
	SSKManager *sskManager = [SSKManager sharedManager];
	sskManager.uuidForReview = [self uuid];
	[sskManager lookForProducts:[NSDictionary dictionaryWithObjectsAndKeys:
#if IS_FULL()
								 [NSArray arrayWithObject:kServiceEditorPurchase], @"Non-Consumables", nil]];
#else
	[NSArray arrayWithObject:kAdFreePurchase], @"Non-Consumables", nil]];
#endif

	return YES;
}

/* open url after ios 4.2 */
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	return [self application:application handleOpenURL:url];
}

/* open url prior to ios 4.2 */
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	if([url.scheme hasPrefix:[NSString stringWithFormat:@"fb%@", SHKCONFIG(facebookAppId)]])
		return [SHKFacebook handleOpenURL:url];

	if([url.path isEqualToString:@"/settings"])
	{
		cachedURL = url;
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"About to import data", @"Title of Alert when import triggered")
															  message:NSLocalizedString(@"You are about to import data into this application. All existing settings will be lost!", @"Message explaining what will happen on import")
															 delegate:self
													cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
													otherButtonTitles:NSLocalizedString(@"Import", @"Button executing import"), nil];
		alert.tag = TAG_URL;
		[alert show];
	}
	// open bouquets list, bouquets are always on index 0 of the viewControllers
	else if([url.path isEqualToString:@"/bouquets"])
	{
		tabBarController.selectedIndex = 0;
	}
	// redeem gift code
	// Syntax: /redeem/productIdentifier/code
	else if([url.path hasPrefix:@"/redeem"])
	{
		NSArray *components = [url.path componentsSeparatedByString:@"/"];
		if(components.count > 3)
		{
			NSString *productIdentifier = [components objectAtIndex:2];
			NSString *code = [components objectAtIndex:3];
			SSKManager *sskManager = [SSKManager sharedManager];
			[sskManager redeemCode:code
			  forProductIdentifier:productIdentifier
				 completionHandler:^(NSString *productIdentifier)
			{
				MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:self.window];
				[self.window addSubview:hud];
				hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
				hud.mode = MBProgressHUDModeCustomView;
				hud.labelText = NSLocalizedString(@"Code redeemed", @"HUD: Code was successfully used to unlock in-app-purchase");
				hud.removeFromSuperViewOnHide = YES;
				dispatch_async(dispatch_get_main_queue(), ^{
					[hud show:YES];
					[hud hide:YES afterDelay:2];
				});
			}
					  errorHandler:^(NSString *productIdentifier, NSError *error)
			{
				const UIAlertView *notification = [[UIAlertView alloc] initWithTitle:[error localizedFailureReason]
																			 message:[error localizedRecoverySuggestion]
																			delegate:nil
																   cancelButtonTitle:@"OK"
																   otherButtonTitles:nil];
				[notification performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
			}];
		}
	}
	return YES;
}

/* close app */
- (void)applicationWillTerminate:(UIApplication *)application
{
#if IS_FULL()
	// remove past event
	[[EPGCache sharedInstance] cleanCache];
#endif
	// Save our connection array
	[RemoteConnectorObject saveConnections];
	[RemoteConnectorObject disconnect];
}

/* back to foreground */
- (void)applicationWillEnterForeground:(UIApplication *)application
{
	BOOL promptForRating = YES;
	if([self checkForPicons])
	{
		promptForRating = NO;
	}

	[Appirater appEnteredForeground:promptForRating];
	if(wasSleeping)
	{
		[tabBarController viewWillAppear:YES];
		[tabBarController viewDidAppear:YES];
	}
}

/* backgrounded */
- (void)applicationDidEnterBackground:(UIApplication *)application
{
#if IS_FULL()
	// remove past event
	[[EPGCache sharedInstance] cleanCache];
#endif
	// reset reference date
	[NSDateFormatter resetReferenceDate];

	// stop bonjour discovery which might have been running since the app started
	// otherwise this is a noop
	[RemoteConnectorObject stop];

	// Save our connection array
	[RemoteConnectorObject saveConnections];
	[tabBarController viewWillDisappear:NO];
	[tabBarController viewDidDisappear:NO];
	wasSleeping = YES;
}

- (void)addNetworkOperation
{
	++networkIndicatorCount;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)removeNetworkOperation
{
	if(--networkIndicatorCount <= 0)
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		networkIndicatorCount = 0;
	}
}

#pragma mark Picons

- (BOOL)checkForPicons
{
	glob_t gt;
	if(glob(kPiconGlob, GLOB_TILDE, NULL, &gt) == 0)
	{
		NSInteger i = 0;
		for (; i < gt.gl_matchc; ++i)
		{
			int len = strlen(gt.gl_pathv[i]);
			cachedFilename = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:gt.gl_pathv[i] length:len];

			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import Picons?", @"Title of Alert when a zip file was found in the documents folder possibly containing picons.")
																  message:[NSString stringWithFormat:NSLocalizedString(@"A zip-file (%s) was found in your Documents folder.\nUnpack and delete it now?\n\nThis message will show on every application launch with a zip-file in the Documents folder!", @"Message explaining what what happens on zip-file import."), basename(gt.gl_pathv[i])]
																 delegate:self
														cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
														otherButtonTitles:NSLocalizedString(@"Extract", @"Button executing zip extraction/deletion"), nil];
			alert.tag = TAG_ZIP;
			[alert show];
			return YES;
		}
	}
	globfree(&gt);
	return NO;
}

- (void)unpackPicons
{
	@autoreleasepool {

		HUNZIP huz = {0};
		ZIPENTRY ze = {0,0,0,0,0,0,0,{0}};
		DWORD numitems = 0;
		DWORD numdirs = 0;
		NSString *message = nil;
		DWORD archive = UnzipOpenFileA(&huz, [cachedFilename cStringUsingEncoding:NSASCIIStringEncoding], NULL);

		ze.Index = (DWORD)-1;
		if(archive != ZR_OK || UnzipGetItem(huz, &ze))
		{
			NSLog(@"archive == %lu, %@", archive, cachedFilename);
			message = NSLocalizedString(@"Unable to extract zip-file!", @"Zip-Extraction failed");
		}
		else
		{
			numitems = ze.Index;

			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documents = [paths objectAtIndex:0];
			NSFileManager *fileManager = [NSFileManager defaultManager];
			for(ze.Index = 0; ze.Index < numitems; ++(ze.Index))
			{
				if (UnzipGetItem(huz, &ze))
					break;

				// skip directory elements
				if(ze.Attributes & S_IFDIR)
				{
					++numdirs;
					continue;
				}

				@autoreleasepool {

					const char *base = basename(ze.Name); // picons might be in a subfolder, we don't want that
					NSString *name = [[NSString alloc] initWithBytesNoCopy:(void *)base length:strlen(base) encoding:NSASCIIStringEncoding freeWhenDone:NO];
					NSString *fullname = [documents stringByAppendingPathComponent:name];
					UnzipItemToFile(huz, [fileManager fileSystemRepresentationWithPath:fullname], &ze);

				}
			}

			NSError *error = nil;
			if([[NSFileManager defaultManager] removeItemAtPath:cachedFilename error:&error] != YES)
			{
				message = NSLocalizedString(@"Failed to remove zip-file!\nPlease remove it manually using iTunes.", @"Removal of zip-file failed after extraction.");
				NSLog(@"failed to delete %@", cachedFilename);
			}
		}

		UnzipClose(huz);
		UIAlertView *alert = nil;
		if(message)
		{
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
											   message:message
											  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		}
		else
		{
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Done", @"")
											   message:[NSString stringWithFormat:NSLocalizedString(@"%d files extracted successfully.", @"zip-file was extracted without any errors."), numitems-numdirs]
											  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
		}
		[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];

		cachedFilename = nil;

	}
}

#pragma mark -
#pragma mark UIAlertViewDelegate
#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// import
	if(buttonIndex == alertView.firstOtherButtonIndex && alertView.tag == TAG_URL)
	{
		NSString *queryString = [cachedURL query];
		NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];

		// iterate over components
		for(NSString *components in [queryString componentsSeparatedByString:@"&"])
		{
			NSArray *compArr = [components componentsSeparatedByString:@":"];
			if([compArr count] != 2)
			{
				// how to handle failure?
				continue;
			}
			NSString *key = [compArr objectAtIndex:0];
			NSString *value = [compArr objectAtIndex:1];

			// base64 encoded connection plist
			if([key isEqualToString:@"import"])
			{
				NSData *data = [NSData dataFromBase64String:value];
				if(!data) return;
				NSArray *arr = [NSArray arrayWithData:data];
				if(!arr) return;
				[arr writeToFile: [kConfigPath stringByExpandingTildeInPath] atomically: YES];

				// trigger reload
				[RemoteConnectorObject disconnect];
				[RemoteConnectorObject loadConnections];
			}
			else if([key isEqualToString:kActiveConnection])
			{
				[stdDefaults setObject:[NSNumber numberWithInteger:[value integerValue]] forKey:kActiveConnection];
			}
			else if([key isEqualToString:kVibratingRC])
			{
				[stdDefaults setBool:[value boolValue] forKey:kVibratingRC];
			}
			else if([key isEqualToString:kMessageTimeout])
			{
				[stdDefaults setValue:value forKey:kMessageTimeout];
			}
			else if([key isEqualToString:kPrefersSimpleRemote])
			{
				[stdDefaults setBool:[value boolValue] forKey:kPrefersSimpleRemote];
			}
			else if([key isEqualToString:kTimeoutKey])
			{
				[stdDefaults setInteger:[value integerValue] forKey:kTimeoutKey];
			}
			else if([key isEqualToString:kSearchHistoryLength])
			{
				[stdDefaults setInteger:[value integerValue] forKey:kSearchHistoryLength];
			}
			else if([key isEqualToString:kSeparateEpgByDay])
			{
				[stdDefaults setBool:[value boolValue] forKey:kSeparateEpgByDay];
			}
			else
			{
				// hmm?
				continue;
			}
		}
		// make sure data is safe
		[stdDefaults synchronize];

		// let main view reload its data
		[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
	}
	else if(buttonIndex == alertView.firstOtherButtonIndex && alertView.tag == TAG_ZIP)
	{
		[NSThread detachNewThreadSelector:@selector(unpackPicons) toTarget:self withObject:nil];
	}
	cachedURL = nil;
}

@end
