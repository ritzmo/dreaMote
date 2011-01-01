//
//  MovieSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 26.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "MovieProtocol.h"

/*!
 @brief MovieSourceDelegate.

 Objects wanting to be called back by a Movie Source (e.g. Movie list
 reader) need to implement this Protocol.
 */
@protocol MovieSourceDelegate <NSObject>

/*!
 @brief New object was created and should be added to list.
 
 @param anItem Movie to add.
 */
- (void)addMovie: (NSObject<MovieProtocol> *)anItem;

@end

