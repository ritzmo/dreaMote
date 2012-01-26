//
//  LocationListController.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LocationSourceDelegate.h"
#import "MovieListController.h"
#import "ReloadableListController.h"


/*!
 @brief Location was selected.

 @param newLocation Location that was selected.
 @param canceling Selection was canceled.
 */
typedef void (^locationCallback_t)(NSObject<LocationProtocol> *newLocation, BOOL canceling);

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
	MovieListController *_movieListController; /*!< @brief Caches Movie List instance. */
}

/*!
 @brief Prefetch location list
 @note We use this to force a refresh of the location list before the movie list or else we
  might run into a timeout there
 */
- (void)forceRefresh;



/*!
 @brief Location Selection Callback.
 */
@property (nonatomic, copy) locationCallback_t callback;

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
