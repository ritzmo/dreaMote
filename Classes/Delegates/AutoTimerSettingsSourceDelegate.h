//
//  AutoTimerSettingsSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 02.12.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DataSourceDelegate.h"
#import <Objects/Generic/AutoTimerSettings.h>

/*!
 @brief AutoTimerSettingsSourceDelegate.

 Objects wanting to be called back by an AutoTimer Settings Source
 need to implement this Protocol.
 */
@protocol AutoTimerSettingsSourceDelegate <DataSourceDelegate>

/*!
 @brief Settings were read.

 @param anItem AutoTimerSettings instance.
 */
- (void)autotimerSettingsRead:(AutoTimerSettings *)anItem;

@end
