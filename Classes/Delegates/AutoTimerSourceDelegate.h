//
//  AutoTimerSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 19.03.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DataSourceDelegate.h"
#import "../Objects/Generic/AutoTimer.h"

/*!
 @brief AutoTimerSourceDelegate.
 
 Objects wanting to be called back by an AutoTimer Source
 need to implement this Protocol.
 */
@protocol AutoTimerSourceDelegate <DataSourceDelegate>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem AutoTimer to add.
 */
- (void)addAutoTimer: (AutoTimer *)anItem;

/*!
 @brief AutoTimer version was determined.

 @param aVersion AutoTimer Version.
 */
- (void)gotAutoTimerVersion:(NSNumber *)aVersion;

@end
