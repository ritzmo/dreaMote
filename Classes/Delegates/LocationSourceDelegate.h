//
//  LocationSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "LocationProtocol.h"

/*!
 @brief LocationSourceDelegate.

 Objects wanting to be called back by a Location Source (e.g. Location list
 reader) need to implement this Protocol.
 */
@protocol LocationSourceDelegate <NSObject>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem Location to add.
 */
- (void)addLocation: (NSObject<LocationProtocol> *)anItem;

@end

