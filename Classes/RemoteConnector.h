/*
 *  RemoteConnector.h
 *  Untitled
 *
 *  Created by Moritz Venn on 08.03.08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 *
 */

#include "Service.h"
#include "Volume.h"
#include "Timer.h"

@protocol RemoteConnector

- (id)initWithAddress:(NSString *) address;
+ (id <RemoteConnector>*)createClassWithAddress:(NSString *) address;
- (NSArray *)fetchServices;
- (NSArray *)fetchEPG:(Service *) service;
- (NSArray *)fetchTimers;
- (Volume *)getVolume;

// XXX: we might want to return a dictionary which contains retval / explain for these
- (BOOL)zapTo:(Service *) service;
- (void)shutdown;
- (void)standby;
- (void)reboot;
- (void)restart;
- (BOOL)toggleMuted;
- (void)setVolume:(int) newVolume;
- (void)addTimer:(Timer *) newTimer;
- (void)editTimer:(Timer *) oldTimer: (Timer *) newTimer;
- (void)delTimer:(Timer *) oldTimer;

@end
