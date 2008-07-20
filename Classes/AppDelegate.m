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

@implementation AppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;

- init {
	if (self = [super init]) {
		// Your initialization code here
	}
	return self;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	    // low on memory: do whatever you can to reduce your memory foot print here
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	// XXX: connection is not manageable like this and this should be placed somewhere elese
	[RemoteConnectorObject _setSharedRemoteConnector: (NSObject <RemoteConnector>*)[Enigma2Connector createClassWithAddress:@"http://192.168.178.22"]];
/*
	// Create window
	_window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	[_window setBackgroundColor:[UIColor whiteColor]];

	// set up main view navigation controller
	MainViewController *navController = [[MainViewController alloc] init];
	
	// create a navigation controller using the new controller
	_navigationController = [[UINavigationController alloc] initWithRootViewController:navController];
	//self.navigationController.navigationBarStyle = UIBarStyleDefault; // TODO: upgraded sdk
	
	[navController release];
*/
	// Show the window and view
	[_window addSubview:[_navigationController view]];
	[_window makeKeyAndVisible];
}

- (void)dealloc {
	[_window release];
	[_navigationController release];

	[super dealloc];
}

@end
