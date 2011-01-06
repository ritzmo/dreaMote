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
@class CXMLDocument;
@protocol LocationListDelegate;

/*!
 @brief Location list.
 
 Display list of known locations and start MovieListController on selected ones.
 */
@interface LocationListController : ReloadableListController <UIActionSheetDelegate,
													UITableViewDelegate,
													UITableViewDataSource, LocationSourceDelegate>
{
@private
	NSMutableArray *_locations; /*!< @brief Location List. */
	BOOL _refreshLocations; /*!< @brief Refresh Location List on next open? */
	BOOL _isSplit; /*!< @brief Split mode? */
	MovieListController *_movieListController; /*!< @brief Caches Movie List instance. */
	NSObject<LocationListDelegate> *_delegate; /*!< @brief Delegate. */

	CXMLDocument *_locationXMLDoc; /*!< @brief Location XML. */
}

/*!
 @brief Set Service Selection Delegate.
 
 This Function is required for Timers as they will use the provided Callback when you change the
 Service of a Timer.
 
 @param delegate New delegate object.
 */
- (void)setDelegate: (NSObject<LocationListDelegate> *) delegate;

/*!
 @brief Prefetch location list
 @note We use this to force a refresh of the location list before the movie list or else we
  might run into a timeout there
 */
- (void)forceRefresh;

/*!
 @brief Controlled by a split view controller?
 */
@property (nonatomic) BOOL isSplit;

/*!
 @brief Movie List
 */
@property (nonatomic, retain) IBOutlet MovieListController *movieListController;

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
