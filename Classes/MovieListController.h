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
	FuzzyDateFormatter *dateFormatter; /*!< @brief Date Formatter. */

	MovieViewController *movieViewController; /*!< @brief Cached Movie Detail View. */
	CXMLDocument *movieXMLDoc; /*!< Current Movie XML Document. */
	BOOL refreshMovies; /*!< @brief Should Movie List be refreshed on next open? */
}

@end
