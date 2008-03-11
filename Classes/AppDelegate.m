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

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	// XXX: connection is not manageable like this and this should be placed somewhere elese
	[RemoteConnectorObject _setSharedRemoteConnector: (NSObject <RemoteConnector>*)[Enigma2Connector createClassWithAddress:@"http://192.168.45.38"]];

	// Create window
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	[self.window setBackgroundColor:[UIColor whiteColor]];
	
	// set up main view navigation controller
	MainViewController *navController = [[MainViewController alloc] init];
	
	// create a navigation controller using the new controller
	self.navigationController = [[UINavigationController alloc] initWithRootViewController:navController];
	self.navigationController.navigationBarStyle = UIBarStyleDefault;
	
	[navController release];
	
	// Show the window and view
	[self.window addSubview:[self.navigationController view]];
	[self.window makeKeyAndVisible];
}

- (void)dealloc {
	[_window release];
	[_navigationController release];

	[super dealloc];
}

@end
