//
//  TimerSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 26.06.09.
//  Copyright 2009-2010 Moritz Venn. All rights reserved.
//

#import "TimerProtocol.h"

/*!
 @brief TimerSourceDelegate.

 Objects wanting to be called back by a Timer Source (e.g. Timer reader)
 need to implement this Protocol.
 */
@protocol TimerSourceDelegate <NSObject>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem Timer to add.
 */
- (void)addTimer: (NSObject<TimerProtocol> *)anItem;

@end

