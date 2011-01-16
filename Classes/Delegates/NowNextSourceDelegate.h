//
//  NowNextSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "EventProtocol.h"

#import "DataSourceDelegate.h"

/*!
 @brief NowSourceDelegate.

 Objects wanting to be called back by a Now Source (e.g. Service list)
 need to implement this Protocol.
 */
@protocol NowSourceDelegate <DataSourceDelegate>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem Event to add.
 */
- (void)addNowEvent: (NSObject<EventProtocol> *)anItem;

@end

/*!
 @brief NextSourceDelegate.

 Objects wanting to be called back by a Next Source (e.g. Service list)
 need to implement this Protocol.
 */
@protocol NextSourceDelegate <DataSourceDelegate>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem Event to add.
 */
- (void)addNextEvent: (NSObject<EventProtocol> *)anItem;

@end

