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
#import "MGSplitViewController.h" /* MGSplitViewControllerDelegate */

// Forward declarations...
@class MovieViewController;
@class BaseXMLReader;

/*!
 @brief Movie List.
 
 Lists movies and opens MovieViewController upon selection.
 Removing a movie is also allowed but not always shown as not all RemoteConnectors allow it.
 */
@interface MovieListController : ReloadableListController <UITableViewDelegate,
													UITableViewDataSource,
													MovieSourceDelegate,
#if IS_FULL()
													UISearchDisplayDelegate,
#endif
													MGSplitViewControllerDelegate>
{
@private
	UIPopoverController *popoverController;
	NSMutableArray *_movies; /*!< @brief Movie List. */
	NSDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */
	UIBarButtonItem *_sortButton; /*!< @brief Sort Button. */
	NSArray *_currentKeys; /*!< @brief Cached keys. */
	NSMutableDictionary *_characters; /*!< @brief First characters -> movies for current list. */

#if IS_FULL()
	NSMutableArray *_filteredMovies; /*!< @brief Filtered list of movies when searching. */
	UISearchBar *_searchBar; /*!< @brief Search bar. */
	UISearchDisplayController *_searchDisplay; /*!< @brief Search display. */
#endif

	MovieViewController *_movieViewController; /*!< @brief Cached Movie Detail View. */
	BaseXMLReader *_xmlReader; /*!< Current Movie XML Reader. */
	BOOL _refreshMovies; /*!< @brief Should Movie List be refreshed on next open? */
	BOOL _isSplit; /*!< @brief Split mode? */	
	BOOL _sortTitle; /*!< @brief Sort by title? */

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
@property (nonatomic, strong) NSString *currentLocation;

/*!
 @brief Controlled by a split view controller?
 */
@property (nonatomic) BOOL isSplit;

/*!
 @brief Movie View Controller
 */
@property (strong) MovieViewController *movieViewController;

/*!
 @brief Currently reloading.
 */
@property (nonatomic, readonly) BOOL reloading;

/*!
 @breif View will reapper.
 */
@property (nonatomic) BOOL willReappear;

@end
