//
//  MovieListController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MovieSourceDelegate.h"

// Forward declarations...
@class FuzzyDateFormatter;
@class MovieViewController;
@class CXMLDocument;

/*!
 @brief Movie List.
 
 Lists movies and opens MovieViewController upon selection.
 Removing a movie is also allowed but not always shown as not all RemoteConnectors allow it.
 */
@interface MovieListController : UIViewController <UITableViewDelegate, UITableViewDataSource,
													MovieSourceDelegate>
{
@private
	NSMutableArray *_movies; /*!< @brief Movie List. */
	FuzzyDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */

	MovieViewController *_movieViewController; /*!< @brief Cached Movie Detail View. */
	CXMLDocument *_movieXMLDoc; /*!< Current Movie XML Document. */
	BOOL _refreshMovies; /*!< @brief Should Movie List be refreshed on next open? */
}

@end
