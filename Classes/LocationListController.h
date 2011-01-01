//
//  LocationListController.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MovieListController.h"
#import "LocationSourceDelegate.h"

// Forward declaration
@class CXMLDocument;

/*!
 @brief Location list.
 
 Display list of known locations and start MovieListController on selected ones.
 */
@interface LocationListController : UIViewController <UIActionSheetDelegate, UITableViewDelegate,
													UITableViewDataSource, LocationSourceDelegate>
{
@private
	NSMutableArray *_locations; /*!< @brief Location List. */
	BOOL _refreshLocations; /*!< @brief Refresh Location List on next open? */
	BOOL _isSplit; /*!< @brief Split mode? */
	MovieListController *_movieListController; /*!< @brief Caches Movie List instance. */

	CXMLDocument *_locationXMLDoc; /*!< @brief Location XML. */
}

/*!
 @brief Controlled by a split view controller?
 */
@property (nonatomic) BOOL isSplit;

/*!
 @brief Movie List
 */
@property (nonatomic, retain) IBOutlet MovieListController *movieListController;

@end
