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
@class CXMLDocument;

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
	NSDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */
	UIPopoverController *popoverController; /*!< @brief Popover controller */

	BOOL _useSections; /*!< @brief Use sections? */
	NSTimeInterval _firstDay; /*!< @brief First day with events (00:00) if using sections / day. */
	NSMutableArray *_sectionOffsets; /*!< @brief Array of first indices. */

	CXMLDocument *_eventXMLDoc; /*!< @brief Event XML Document. */
	ServiceListController *_serviceListController; /*!< @brief Parent/Service List controller. */
	EventViewController *_eventViewController; /*!< @brief Cached Event Detail View. */
	ServiceZapListController *_zapListController; /*!< @brief Zap List controller. */

	UISearchBar *_searchBar; /*!< @brief Search bar, either for event search or in full version. */
#if IS_FULL()
	NSMutableArray *_filteredEvents; /*!< @brief Filtered list of events when searching. */
	UISearchDisplayController *_searchDisplay; /*!< @brief Search display. */
#endif

#if INCLUDE_FEATURE(Ads)
@private
	id _adBannerView;
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
@property (nonatomic, retain) NSObject<ServiceProtocol> *service;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, retain) NSDateFormatter *dateFormatter;

/*!
 @brief Popover Controller.
 */
@property (nonatomic, retain) UIPopoverController *popoverController;

/*!
 @brief Serivce List.
 */
@property (nonatomic, assign) ServiceListController *serviceListController;

@end
