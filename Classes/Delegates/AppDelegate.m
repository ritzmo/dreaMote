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

#import "RemoteConnectorObject.h"

@implementation AppDelegate

@synthesize window;
@synthesize tabBarController;

- (id)init
{
	if((self = [super init]))
	{
		wasSleeping = NO;
	}
	return self;
}

/* finished launching */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber *activeConnectionId = [NSNumber numberWithInteger: 0];
	NSString *testValue = nil;

	// 0.1-0 configuration
	testValue = [stdDefaults stringForKey: kRemoteHost];
	if(testValue != nil)
	{
		// Build Connection Dict from old defaults
		NSDictionary *connection = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[stdDefaults stringForKey: kRemoteHost], kRemoteHost,
									[stdDefaults stringForKey: kUsername], kUsername,
									[stdDefaults stringForKey: kPassword], kPassword,
									[NSNumber numberWithInteger:
												[stdDefaults integerForKey: kConnector]], kConnector,
									nil];

		// Load, edit and save new connections array
		[RemoteConnectorObject loadConnections];
		NSMutableArray *connections = [RemoteConnectorObject getConnections];
		[connections addObject: connection];
		[RemoteConnectorObject saveConnections];

		// Remove old defaults
		[stdDefaults removeObjectForKey: kRemoteHost];
		[stdDefaults removeObjectForKey: kUsername];
		[stdDefaults removeObjectForKey: kPassword];
		[stdDefaults removeObjectForKey: kConnector];

		// Register new items
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
									 activeConnectionId, kActiveConnection,
									 @"NO", kVibratingRC,
									 @"YES", kConnectionTest,
									 @"10", kMessageTimeout,
									 @"YES", kPrefersSimpleRemote,
									 nil];

		[stdDefaults registerDefaults: appDefaults];
		[stdDefaults synchronize];
	}
	// 0.2-0 configuration
	else if((testValue = [stdDefaults stringForKey: kActiveConnection]) == nil)
	{
		// since no default values have been set (i.e. no preferences file created), create it here
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
										activeConnectionId, kActiveConnection,
										@"NO", kVibratingRC,
										@"YES", kConnectionTest,
										@"10", kMessageTimeout,
										@"YES", kPrefersSimpleRemote,
										nil];

		[stdDefaults registerDefaults: appDefaults];
		[stdDefaults synchronize];
	}
	// 0.2+
	else
	{
		activeConnectionId = [NSNumber numberWithInteger: [testValue integerValue]];
		// 0.2.808+
		if([stdDefaults stringForKey: kPrefersSimpleRemote] == nil)
		{
			[stdDefaults setBool:YES forKey:kPrefersSimpleRemote];
			[stdDefaults synchronize];
		}
	}

	if([RemoteConnectorObject loadConnections])
		[RemoteConnectorObject connectTo: [activeConnectionId integerValue]];
	
	// Show the window and view
	[window addSubview: tabBarController.view];
	[window makeKeyAndVisible];

	// for some reason handleOpenURL did not get called in my tests on iOS prior to 4.0
	// so we call it here manually… the worst thing that can happen is that the data
	// gets parsed twice so we have a little more computation to do.
	NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
	if(url && ![UIDevice runsIos4OrBetter])
	{
		[self application:application handleOpenURL:url];
	}

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
	NSString *queryString = [url query];
	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];

	// iterate over components
	for(NSString *components in [queryString componentsSeparatedByString:@"&"])
	{
		NSArray *compArr = [components componentsSeparatedByString:@":"];
		if([compArr count] != 2)
		{
			// how to handle failure?
			continue; //return NO;
		}
		NSString *key = [compArr objectAtIndex:0];
		NSString *value = [compArr objectAtIndex:1];

		// base64 encoded connection plist
		if([key isEqualToString:@"import"])
		{
			NSData *data = [NSData dataFromBase64String:value];
			if(!data) return NO;
			NSArray *arr = [NSArray arrayWithData:data];
			if(!arr) return NO;
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
			continue; //return NO;
		}
	}
	// make sure data is safe
	[stdDefaults synchronize];

	// let main view reload its data
	[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
	return YES;
}

/* close app */
- (void)applicationWillTerminate:(UIApplication *)application
{
	// Save our connection array
	[RemoteConnectorObject saveConnections];
	[RemoteConnectorObject disconnect];
}

/* back to foreground */
- (void)applicationDidBecomeActive:(UIApplication *)application
{
	if(wasSleeping)
	{
		[tabBarController viewWillAppear:YES];
		[tabBarController viewDidAppear:YES];
	}
}

/* backgrounded */
- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Save our connection array
	[RemoteConnectorObject saveConnections];
	[tabBarController viewWillDisappear:NO];
	[tabBarController viewDidDisappear:NO];
	wasSleeping = YES;
}

/* dealloc */
- (void)dealloc
{
	[window release];
	[tabBarController release];

	[super dealloc];
}

@end
