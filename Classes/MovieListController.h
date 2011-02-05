//
//  MovieListController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MovieSourceDelegate.h"
#import "ReloadableListController.h"

// Forward declarations...
@class MovieViewController;
@class CXMLDocument;

/*!
 @brief Movie List.
 
 Lists movies and opens MovieViewController upon selection.
 Removing a movie is also allowed but not always shown as not all RemoteConnectors allow it.
 */
@interface MovieListController : ReloadableListController <UITableViewDelegate,
													UITableViewDataSource,
													MovieSourceDelegate,
													UISplitViewControllerDelegate>
{
@private
	UIPopoverController *popoverController;
	NSMutableArray *_movies; /*!< @brief Movie List. */
	NSDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */

	MovieViewController *_movieViewController; /*!< @brief Cached Movie Detail View. */
	CXMLDocument *_movieXMLDoc; /*!< Current Movie XML Document. */
	BOOL _refreshMovies; /*!< @brief Should Movie List be refreshed on next open? */
	BOOL _isSplit; /*!< @brief Split mode? */	

	NSString *_currentLocation; /*!< @brief Current Location. */
}

/*!
 @brief Move movie selection to next item and return movie.
 @note If current movie is last in list, don't move selection and return nil.

 @return Newly selected movie.
 */
- (NSObject<MovieProtocol> *)nextMovie;

/*!
 @brief Move movie selection to previous item and return movie.
 @note If current movie is first in list, don't move selection and return nil.

 @return Newly selected movie.
 */
- (NSObject<MovieProtocol> *)previousMovie;

/*!
 @brief Currently displayed directory
 */
@property (nonatomic, retain) NSString *currentLocation;

/*!
 @brief Controlled by a split view controller?
 */
@property (nonatomic) BOOL isSplit;

/*!
 @brief Movie View Controller
 */
@property (retain) MovieViewController *movieViewController;

/*!
 @breif View will reapper.
 */
@property (nonatomic) BOOL willReappear;

@end
