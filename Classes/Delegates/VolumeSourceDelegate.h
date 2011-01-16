//
//  VolumeSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 26.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "Volume.h"

#import "DataSourceDelegate.h"

/*!
 @brief VolumeSourceDelegate.

 Objects wanting to be called back by a Volume Source (e.g. Volume reader)
 need to implement this Protocol.
 */
@protocol VolumeSourceDelegate <DataSourceDelegate>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem Volume to add.
 */
- (void)addVolume: (GenericVolume *)anItem;

@end

