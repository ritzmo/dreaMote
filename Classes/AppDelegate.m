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
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];

	BOOL configLoaded = [RemoteConnectorObject loadConnections];
	NSNumber *activeConnectionId = [NSNumber numberWithInteger: (configLoaded) ? 0 : -1];

	NSString *testValue = [[NSUserDefaults standardUserDefaults] stringForKey: kActiveConnection];
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

	if(configLoaded)
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
