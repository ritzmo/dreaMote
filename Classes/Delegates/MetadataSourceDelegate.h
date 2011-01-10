//
//  MetadataSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MetadataProtocol.h"

/*!
 @brief MetadataSourceDelegate.

 Objects wanting to be called back by a Metadata Source (e.g. Mediaplayer)
 need to implement this Protocol.
 */
@protocol MetadataSourceDelegate <NSObject>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem Metadata to add.
 */
- (void)addMetadata: (NSObject<MetadataProtocol> *)anItem;

@end

