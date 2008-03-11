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
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;

@end
