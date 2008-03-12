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
 - (NSArray *)fetchEPG: (Service *) service;
 - (NSArray *)fetchTimers;
 - (BOOL)zapTo:(Service *) service;
 - (void)shutdown;
 - (void)standby;
 - (void)reboot;
 - (void)restart;
 - (Volume *)getVolume;
 - (BOOL)toggleMuted;
 - (void)setVolume:(int) newVolume;
 - (void)addTimer:(Timer *) newTimer;
 - (void)editTimer:(Timer *) oldTimer: (Timer *) newTimer;

@end
