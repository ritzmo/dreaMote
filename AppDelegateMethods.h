/*
 *  AppDelegateMethods.h
 *  Untitled
 *
 *  Created by Moritz Venn on 08.03.08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

@class Service;
@class Volume;

@interface AppDelegateMethods

- (void)zapToService:(Service *)service;
- (NSArray *)getServices;
- (NSArray *)getTimers;
- (NSArray *)getEPGForService: (Service *)service;
- (void)standby;
- (void)reboot;
- (void)restart;
- (void)shutdown;
- (Volume *)getVolume;
- (BOOL)toggleMuted;
- (void)setVolume:(int) newVolume;

@end
