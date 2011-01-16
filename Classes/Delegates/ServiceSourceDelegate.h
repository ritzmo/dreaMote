//
//  ServiceSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 26.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "ServiceProtocol.h"

#import "DataSourceDelegate.h"

/*!
 @brief ServiceSourceDelegate.

 Objects wanting to be called back by a Service Source (e.g. Favourites
 reader) need to implement this Protocol.
 */
@protocol ServiceSourceDelegate <DataSourceDelegate>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem Service to add.
 */
- (void)addService: (NSObject<ServiceProtocol> *)anItem;

@end

