//
//  AppDelegate.m
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import "RemoteConnectorObject.h"

@implementation AppDelegate

@synthesize window;
@synthesize navigationController;

- (id)init
{
	if (self = [super init])
	{
		// Your initialization code here
	}
	return self;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	// Show the window and view
	[window addSubview: navigationController.view];
	[window makeKeyAndVisible];

	NSNumber *activeConnectionId = [NSNumber numberWithInteger: 0];
	NSString *testValue = nil;

	// Try to read 0.1-0 configuration
	testValue = [[NSUserDefaults standardUserDefaults] stringForKey: kRemoteHost];
	if(testValue != nil)
	{
		// Build Connection Dict from old defaults
		NSDictionary *connection = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[[NSUserDefaults standardUserDefaults] stringForKey: kRemoteHost], kRemoteHost,
									[[NSUserDefaults standardUserDefaults] stringForKey: kUsername], kUsername,
									[[NSUserDefaults standardUserDefaults] stringForKey: kPassword], kPassword,
									[NSNumber numberWithInteger: [[NSUserDefaults standardUserDefaults] integerForKey: kConnector]], kConnector,
									nil];

		// Load, edit and save new connections array
		[RemoteConnectorObject loadConnections];
		NSMutableArray *connections = [RemoteConnectorObject getConnections];
		[connections addObject: connection];
		[RemoteConnectorObject saveConnections];

		// Remove old defaults
		[[NSUserDefaults standardUserDefaults] removeObjectForKey: kRemoteHost];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey: kUsername];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey: kPassword];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey: kConnector];

		// Register new item (kActiveConnection)
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
									 activeConnectionId, kActiveConnection,
									 nil];

		[[NSUserDefaults standardUserDefaults] registerDefaults: appDefaults];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

	testValue = [[NSUserDefaults standardUserDefaults] stringForKey: kActiveConnection];
	if(testValue == nil)
	{
		// no default values have been set, create them here

		// since no default values have been set (i.e. no preferences file created), create it here
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
									  activeConnectionId, kActiveConnection,
									  NO, kVibratingRC,
									  nil];

		[[NSUserDefaults standardUserDefaults] registerDefaults: appDefaults];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	else
		activeConnectionId = [NSNumber numberWithInteger: [testValue integerValue]];

	if([RemoteConnectorObject loadConnections])
		[RemoteConnectorObject connectTo: [activeConnectionId integerValue]];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Save our connection array
	[RemoteConnectorObject saveConnections];
}

- (void)dealloc
{
	[window release];
	[navigationController release];

	[super dealloc];
}

@end
