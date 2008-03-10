//
//  AppDelegate.h
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"
#import "AppDelegateMethods.h"

@interface AppDelegate : NSObject  <UIApplicationDelegate> {

@private
    UIWindow *_window;
	
	UINavigationController *_navigationController;
	
	id <RemoteConnector> *_connection;
}

- (NSArray*)getServices;
- (NSArray*)getTimers;
- (void)zapToService:(Service *)service;
- (void)standby;
- (void)reboot;
- (void)restart;
- (void)shutdown;
- (Volume*)getVolume;
- (BOOL)toggleMuted;
- (void)setVolume:(int) newVolume;

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) id <RemoteConnector> *connection;

@end
