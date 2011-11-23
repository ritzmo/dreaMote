//
//  EventListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EventSourceDelegate.h"
#import "ReloadableListController.h"
#import "ServiceListController.h"
#import "ServiceZapListController.h" /* ServiceZapListDelegate */

#if INCLUDE_FEATURE(Ads)
#import "iAd/ADBannerView.h"
#endif

// Forward declarations...
@protocol ServiceProtocol;
@class EventViewController;

/*!
 @brief Event List.
 
 Lists events and opens an EventViewController upon selection.
 */
@interface EventListController : ReloadableListController <UITableViewDelegate,
#if INCLUDE_FEATURE(Ads)
													ADBannerViewDelegate,
#endif
													UITableViewDataSource,
													EventSourceDelegate,
													UIScrollViewDelegate,
#if IS_FULL()
													UISearchDisplayDelegate,
													SwipeTableViewDelegate,
#endif
													UIPopoverControllerDelegate,
													UIActionSheetDelegate,
													ServiceZapListDelegate>
{
@protected
	NSMutableArray *_events; /*!< @brief Event List. */
	NSObject<ServiceProtocol> *_service; /*!< @brief Current Service. */

	NSCalendar *_gregorian; /*!< @brief Calendar instance. */
	BOOL _useSections; /*!< @brief Use sections? */
	NSInteger _lastDay; /*!< @brief Last day with events if using sections / day. */
	NSMutableArray *_sectionOffsets; /*!< @brief Array of first indices. */

	ServiceListController *__unsafe_unretained _serviceListController; /*!< @brief Parent/Service List controller. */
	EventViewController *_eventViewController; /*!< @brief Cached Event Detail View. */
	ServiceZapListController *_zapListController; /*!< @brief Zap List controller. */

	UISearchBar *searchBar; /*!< @brief Search bar, either for event search or in full version. */
#if IS_FULL()
	NSMutableArray *_filteredEvents; /*!< @brief Filtered list of events when searching. */
	UISearchDisplayController *_searchDisplay; /*!< @brief Search display. */
#endif

#if INCLUDE_FEATURE(Ads)
@private
	ADBannerView *_adBannerView;
	BOOL _adBannerViewIsVisible;
	CGFloat _adBannerHeight;
#endif
}

/*!
 @brief Open new Event List for given Service.
 
 @param ourService Service to display Events for.
 @return EventListController instance.
 */
+ (EventListController*)forService: (NSObject<ServiceProtocol> *)ourService;

#if INCLUDE_FEATURE(Ads)
/*!
 @brief Create banner view
 */
- (void)createAdBannerView;
#endif

/*!
 @brief Calculate indices of new sections.
 @param allowSearch Are we working on search results?
 */
- (void)sortEventsInSections:(BOOL)allowSearch;

/*!
 @brief Calculate indices of new sections.
 @note Allows search.
 */
- (void)sortEventsInSections;



/*!
 @brief Service.
 */
@property (nonatomic, strong) NSObject<ServiceProtocol> *service;

/*!
 @brief Search bar.
 */
@property (nonatomic, readonly) UISearchBar *searchBar;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

/*!
 @brief Is this view a slave/details view to a split view?
 */
@property (nonatomic) BOOL isSlave;

/*!
 @brief Popover Controller.
 */
@property (nonatomic, strong) UIPopoverController *popoverController;

/*!
 @brief Serivce List.
 */
@property (nonatomic, unsafe_unretained) ServiceListController *serviceListController;

@end
