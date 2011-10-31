//
//  LocationListController.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LocationSourceDelegate.h"
#import "MovieListController.h"
#import "ReloadableListController.h"

// Forward declaration
@class BaseXMLReader;
@protocol LocationListDelegate;

/*!
 @brief Location list.
 
 Display list of known locations and start MovieListController on selected ones.
 */
@interface LocationListController : ReloadableListController <UITableViewDelegate,
															UITableViewDataSource,
															UIAlertViewDelegate,
															LocationSourceDelegate>
{
@private
	NSMutableArray *_locations; /*!< @brief Location List. */
	BOOL _refreshLocations; /*!< @brief Refresh Location List on next open? */
	BOOL _isSplit; /*!< @brief Split mode? */
	BOOL _showDefault; /*!< @brief Show "Default Location"-Folder? */
	MovieListController *_movieListController; /*!< @brief Caches Movie List instance. */
	NSObject<LocationListDelegate> *__unsafe_unretained _delegate; /*!< @brief Delegate. */

	BaseXMLReader *_xmlReader; /*!< @brief Location XML. */
}

/*!
 @brief Prefetch location list
 @note We use this to force a refresh of the location list before the movie list or else we
  might run into a timeout there
 */
- (void)forceRefresh;



/*!
 @brief Location Selection Delegate.
 */
@property (nonatomic, unsafe_unretained) NSObject<LocationListDelegate> *delegate;

/*!
 @brief Controlled by a split view controller?
 */
@property (nonatomic) BOOL isSplit;

/*!
 @brief Movie List
 */
@property (nonatomic, strong) IBOutlet MovieListController *movieListController;

/*!
 @brief Show "Default Location"
 */
@property (nonatomic, assign) BOOL showDefault;

/*!
 @breif View will reapper.
 */
@property (nonatomic) BOOL willReappear;

@end



/*!
 @brief Delegate for LocationListController.
 
 Objects wanting to be called back by a LocationListController need to implement this Protocol.
 */
@protocol LocationListDelegate <NSObject>

/*!
 @brief Location was selected.
 
 @param newLocation Location that was selected.
 */
- (void)locationSelected: (NSObject<LocationProtocol> *)newLocation;

@end
