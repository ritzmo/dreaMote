//
//  MovieSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 26.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "MovieProtocol.h"

#import "DataSourceDelegate.h"

/*!
 @brief MovieSourceDelegate.

 Objects wanting to be called back by a Movie Source (e.g. Movie list
 reader) need to implement this Protocol.
 */
@protocol MovieSourceDelegate <DataSourceDelegate>

/*!
 @brief New object was created and should be added to list.

 @param anItem Movie to add.
 */
- (void)addMovie: (NSObject<MovieProtocol> *)anItem;

/*!
 @brief New objects were created and should be added to list.

 @param items Array of movies to add.
 */
@optional
- (void)addMovies:(NSArray *)items;

@end

