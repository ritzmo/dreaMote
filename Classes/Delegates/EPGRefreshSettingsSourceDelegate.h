//
//  EPGRefreshSettingsSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 15.04.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DataSourceDelegate.h"
#import "../Objects/Generic/EPGRefreshSettings.h"

/*!
 @brief EPGRefreshSettingsSourceDelegate.

 Objects wanting to be called back by an EPGRefresh Settings Source
 need to implement this Protocol.
 */
@protocol EPGRefreshSettingsSourceDelegate <DataSourceDelegate>

/*!
 @brief Settings were read.

 @param anItem EPGRefreshSettings instance.
 */
- (void)epgrefreshSettingsRead: (EPGRefreshSettings *)anItem;

@end
