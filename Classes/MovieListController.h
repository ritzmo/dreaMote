//
//  MovieListController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

// Forward declarations...
@class FuzzyDateFormatter;
@class MovieViewController;
@class CXMLDocument;

/*!
 @brief Movie List.
 */
@interface MovieListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_movies; /*!< @brief Movie List. */
	FuzzyDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */

	MovieViewController *_movieViewController; /*!< @brief Cached Movie Detail View. */
	CXMLDocument *_movieXMLDoc; /*!< Current Movie XML Document. */
	BOOL _refreshMovies; /*!< @brief Should Movie List be refreshed on next open? */
}

@end
