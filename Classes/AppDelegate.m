//
//  AppDelegate.m
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "AppDelegate.h"
#import "Constants.h"

#import "RemoteConnector.h"
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

	NSString *testValue = [[NSUserDefaults standardUserDefaults] stringForKey:kConnector];
	if (testValue == nil)
	{
		// no default values have been set, create them here
		//
		
		// since no default values have been set (i.e. no preferences file created), create it here
		NSDictionary *appDefaults =  [NSDictionary dictionaryWithObjectsAndKeys:
									  @"dreambox", kRemoteHost,
									  @"", kUsername,
									  @"", kPassword,
									  kEnigma2Connector, kConnector,
									  NO, kVibratingRC,
									  nil];

		[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

	[RemoteConnectorObject createConnector: [[NSUserDefaults standardUserDefaults] stringForKey: kRemoteHost] :[[NSUserDefaults standardUserDefaults] stringForKey: kUsername] :[[NSUserDefaults standardUserDefaults] stringForKey: kPassword] : [[[NSUserDefaults standardUserDefaults] stringForKey: kConnector] integerValue]];
}

- (void)dealloc
{
	[window release];
	[navigationController release];

	[super dealloc];
}

@end
