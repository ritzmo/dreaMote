//
//  AppDelegate.m
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "Service.h"
#import "Volume.h"

#import "RemoteConnector.h"
#import "RemoteConnectorObject.h"
#import "Enigma2Connector.h"

NSString *kRemoteHost			= @"remoteHostKey";
NSString *kConnector			= @"connectorKey";

@implementation AppDelegate

@synthesize window;
@synthesize navigationController;

- init
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
		// no default values have been set, create them here based on what's in our Settings bundle info
		//
		NSString *pathStr = [[NSBundle mainBundle] bundlePath];
		NSString *settingsBundlePath = [pathStr stringByAppendingPathComponent:@"Settings.bundle"];
		NSString *finalPath = [settingsBundlePath stringByAppendingPathComponent:@"Root.plist"];
		
		NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:finalPath];
		NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];

		NSString *remoteHostDefault;
		NSNumber *connectorDefault;

		NSDictionary *prefItem;
		for (prefItem in prefSpecifierArray)
		{
			NSString *keyValueStr = [prefItem objectForKey:@"Key"];
			id defaultValue = [prefItem objectForKey:@"DefaultValue"];
			
			if ([keyValueStr isEqualToString:kConnector])
			{
				connectorDefault = defaultValue;
			}
			else if ([keyValueStr isEqualToString:kRemoteHost])
			{
				remoteHostDefault = defaultValue;
			}
		}
		
		// since no default values have been set (i.e. no preferences file created), create it here
		NSDictionary *appDefaults =  [NSDictionary dictionaryWithObjectsAndKeys:
									  remoteHostDefault, kRemoteHost,
									  connectorDefault, kConnector,
									  nil];

		[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

	NSString *remoteHost = [[[NSUserDefaults standardUserDefaults] stringForKey: kRemoteHost] autorelease];
	switch([[[NSUserDefaults standardUserDefaults] stringForKey: kConnector] intValue])
	{
		case kEnigma2Connector:
			[RemoteConnectorObject _setSharedRemoteConnector: (NSObject <RemoteConnector>*)[Enigma2Connector createClassWithAddress: remoteHost]];
			break;
		default:
			break;
	}
}

- (void)dealloc
{
	[window release];
	[navigationController release];

	[super dealloc];
}

@end
