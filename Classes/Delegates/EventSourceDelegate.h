//
//  EventSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 26.06.09.
//  Copyright 2009-2010 Moritz Venn. All rights reserved.
//

#import "EventProtocol.h"

/*!
 @brief EventSourceDelegate.

 Objects wanting to be called back by a Event Source (e.g. EPG reader)
 need to implement this Protocol.
 */
@protocol EventSourceDelegate <NSObject>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem Event to add.
 */
- (void)addEvent: (NSObject<EventProtocol> *)anItem;

@end

