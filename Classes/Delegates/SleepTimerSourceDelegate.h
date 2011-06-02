//
//  SleepTimerSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 02.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DataSourceDelegate.h"
#import "../Objects/Generic/SleepTimer.h"

/*!
 @brief MetadataSourceDelegate.

 Objects wanting to be called back by a SleepTimer Source (e.g. SleepTimer View)
 need to implement this Protocol.
 */
@protocol SleepTimerSourceDelegate <DataSourceDelegate>

/*!
 @brief New object was created and should be added to list.

 @param anItem SleepTimer to add.
 */
- (void)addSleepTimer:(SleepTimer *)anItem;

@end
