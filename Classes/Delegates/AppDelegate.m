//
//  AppDelegate.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import <glob.h>
#include <fcntl.h>
#import "LiteUnzip.h"

#import "NSData+Base64.h"
#import "NSArray+ArrayFromData.h"
#import "UIDevice+SystemVersion.h"

#import "Appirater.h"
#import "BWQuincyManager.h"
#import "RemoteConnectorObject.h"

#if IS_FULL()
	#import "EPGCache.h"
#endif

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

@interface AppDelegate()
- (void)checkReachable;
@end

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

/* dealloc */
- (void)dealloc
{
	[window release];
	[tabBarController release];
	[cachedURL release];
	[cachedFilename release];

	[super dealloc];
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

- (void)checkReachable
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSError *error = nil;
	[[RemoteConnectorObject sharedRemoteConnector] isReachable:&error];

	// this might have changed the features, so handle this like a reconnect
	[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];

	[pool release];
}

#pragma mark -
#pragma mark UIApplicationDelegate
#pragma mark -

/* finished launching */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[[BWQuincyManager sharedQuincyManager] setSubmissionURL:@"http://ritzmo.de/iphone/quincy/crash_v200.php"];

	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber *activeConnectionId = [NSNumber numberWithInteger: 0];
	NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
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
								 nil];
	[stdDefaults registerDefaults:appDefaults];

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

	if([RemoteConnectorObject loadConnections])
	{
		if([RemoteConnectorObject connectTo:[activeConnectionId integerValue]])
		{
			[NSThread detachNewThreadSelector:@selector(checkReachable) toTarget:self withObject:nil];
		}

		// by using mg split view loadView is called to early which might lead to the
		// wrong mode being shown (e.g. only movie list & movie view for enigma2 instead
		// of location list & movie list). posting this notification will trigger the necessary
		// reload.
		[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
	}

	// Show the window and view
	[window addSubview: tabBarController.view];
	[window makeKeyAndVisible];

	// don't prompt for rating if launched with url to avoid (possibly) showing two alerts
	BOOL promptForRating = YES;

	// for some reason handleOpenURL did not get called in my tests on iOS prior to 4.0
	// so we call it here manually… the worst thing that can happen is that the data
	// gets parsed twice so we have a little more computation to do.
	NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
	if(url && ![UIDevice runsIos4OrBetter])
	{
		[self application:application handleOpenURL:url];
		promptForRating = NO;
	}
	// check for .zip files possibly containing picons
	else if([self checkForPicons])
	{
		promptForRating = NO;
	}
	[Appirater appLaunched:promptForRating];

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
	if([url.path isEqualToString:@"/settings"])
	{
		[cachedURL release];
		cachedURL = [url retain];
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"About to import data", @"Title of Alert when import triggered")
															  message:NSLocalizedString(@"You are about to import data into this application. All existing settings will be lost!", @"Message explaining what will happen on import")
															 delegate:self
													cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
													otherButtonTitles:NSLocalizedString(@"Import", @"Button executing import"), nil];
		alert.tag = TAG_URL;
		[alert show];
		[alert release];
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
	// Save our connection array
	[RemoteConnectorObject saveConnections];
	[tabBarController viewWillDisappear:NO];
	[tabBarController viewDidDisappear:NO];
	wasSleeping = YES;
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
			[cachedFilename release];
			cachedFilename = [[[NSFileManager defaultManager] stringWithFileSystemRepresentation:gt.gl_pathv[i] length:len] retain];

			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import Picons?", @"Title of Alert when a zip file was found in the documents folder possibly containing picons.")
																  message:[NSString stringWithFormat:NSLocalizedString(@"A zip-file (%s) was found in your Documents folder.\nUnpack and delete it now?\n\nThis message will show on every application launch with a zip-file in the Documents folder!", @"Message explaining what what happens on zip-file import."), basename(gt.gl_pathv[i])]
																 delegate:self
														cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
														otherButtonTitles:NSLocalizedString(@"Extract", @"Button executing zip extraction/deletion"), nil];
			alert.tag = TAG_ZIP;
			[alert show];
			[alert release];
			return YES;
		}
	}
	globfree(&gt);
	return NO;
}

- (void)unpackPicons
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

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
		goto zipAlert;
	}
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

		NSAutoreleasePool *subpool = [[NSAutoreleasePool alloc] init];

		const char *base = basename(ze.Name); // picons might be in a subfolder, we don't want that
		NSString *name = [[NSString alloc] initWithBytesNoCopy:(void *)base length:strlen(base) encoding:NSASCIIStringEncoding freeWhenDone:NO];
		NSString *fullname = [documents stringByAppendingPathComponent:name];
		UnzipItemToFile(huz, [fileManager fileSystemRepresentationWithPath:fullname], &ze);

		[name release];
		[subpool release];
	}

	NSError *error = nil;
	if([[NSFileManager defaultManager] removeItemAtPath:cachedFilename error:&error] != YES)
	{
		message = NSLocalizedString(@"Failed to remove zip-file!\nPlease remove it manually using iTunes.", @"Removal of zip-file failed after extraction.");
		NSLog(@"failed to delete %@", cachedFilename);
	}

zipAlert:
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
	[alert release];

	[cachedFilename release];
	cachedFilename = nil;

	[pool release];
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
	[cachedURL release];
	cachedURL = nil;
}

@end
