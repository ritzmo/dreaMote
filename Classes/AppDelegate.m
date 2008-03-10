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
#import "Enigma2Connector.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize connection = _connection;

- init {
	if (self = [super init]) {
		// Your initialization code here
	}
	return self;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	// XXX: connection is not manageable like this and this should be placed somewhere elese
	self.connection = (id <RemoteConnector>*)[Enigma2Connector createClassWithAddress:@"http://192.168.45.38"];

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
	[_connection release];

    [super dealloc];
}

- (void)zapToService:(Service *)service
{
	[[self connection] zapTo:service];
}

- (NSArray *)getServices
{
	return [[self connection] fetchServices];
}

- (NSArray *)getTimers
{
	return [[self connection] fetchTimers];
}

- (NSArray *)getEPGForService: (Service *)service
{
	return [[self connection] fetchEPG: service];
}

- (void)standby
{
	[[self connection] standby];
}

- (void)reboot
{
	[[self connection] reboot];
}

- (void)restart
{
	[[self connection] restart];
}

- (void)shutdown
{
	[[self connection] shutdown];
}

- (Volume *)getVolume
{
	return [[self connection] getVolume];
}

- (void)toggleMuted
{
	[[self connection] toggleMuted];

}

- (void)setVolume:(int) newVolume
{
	[[self connection] setVolume: newVolume];
}

@end
