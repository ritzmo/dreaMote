//
//  MovieViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MovieProtocol.h"

/*!
 @brief Movie View.
 */
@interface MovieViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSObject<MovieProtocol> *_movie; /*!< @brief Movie. */
}

/*!
 @brief Open new view for given movie.
 
 @param newMovie Movie to open view for.
 @return MovieViewController instance.
 */
+ (MovieViewController *)withMovie: (NSObject<MovieProtocol> *) newMovie;



/*!
 @brief Movie.
 */
@property (nonatomic, retain) NSObject<MovieProtocol> *movie;

@end
