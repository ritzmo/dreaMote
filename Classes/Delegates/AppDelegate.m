//
//  AppDelegate.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import "NSData+Base64.h"
#import "NSArray+ArrayFromData.h"
#import "UIDevice+SystemVersion.h"

#import "Appirater.h"
#import "RemoteConnectorObject.h"

#if IS_FULL()
	#import "EPGCache.h"
#endif

@implementation AppDelegate

@synthesize window;
@synthesize tabBarController;

- (id)init
{
	if((self = [super init]))
	{
		wasSleeping = NO;
		cachedURL = nil;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[window release];
	[tabBarController release];
	[cachedURL release];

	[super dealloc];
}

- (BOOL)importing
{
	return cachedURL != nil;
}

#pragma mark -
#pragma mark UIApplicationDelegate
#pragma mark -

/* finished launching */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber *activeConnectionId = [NSNumber numberWithInteger: 0];
	NSString *testValue = nil;

	// not configured at all configuration
	if((testValue = [stdDefaults stringForKey: kActiveConnection]) == nil)
	{
		NSString *databaseVersion = [NSString stringWithFormat:@"%d", kCurrentDatabaseVersion];
		// since no default values have been set (i.e. no preferences file created), create it here
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
									 activeConnectionId, kActiveConnection,
									 @"NO", kVibratingRC,
									 @"YES", kConnectionTest,
									 @"10", kMessageTimeout,
									 @"YES", kPrefersSimpleRemote,
									 databaseVersion, kDatabaseVersion,
									 nil];

		[stdDefaults registerDefaults: appDefaults];
		[stdDefaults synchronize];
	}
	// 1.0+ configuration
	else
	{
		activeConnectionId = [NSNumber numberWithInteger:[testValue integerValue]];

		NSInteger integerVersion = -1;
		if((testValue = [stdDefaults stringForKey: kDatabaseVersion]) != nil) // 1.1+
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
	}

	if([RemoteConnectorObject loadConnections])
		[RemoteConnectorObject connectTo: [activeConnectionId integerValue]];
	
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
	[Appirater appEnteredForeground:YES];
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

#pragma mark -
#pragma mark UIAlertViewDelegate
#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// import
	if(buttonIndex == alertView.firstOtherButtonIndex)
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
			else if([key isEqualToString:kConnectionTest])
			{
				[stdDefaults setBool:[value boolValue] forKey:kConnectionTest];
			}
			else if([key isEqualToString:kMessageTimeout])
			{
				[stdDefaults setValue:value forKey:kMessageTimeout];
			}
			else if([key isEqualToString:kPrefersSimpleRemote])
			{
				[stdDefaults setBool:[value boolValue] forKey:kPrefersSimpleRemote];
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
	[cachedURL release];
	cachedURL = nil;
}

@end
