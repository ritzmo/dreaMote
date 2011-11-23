//
//  CurrentViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/EventProtocol.h"
#import "Objects/ServiceProtocol.h"
#import "EventSourceDelegate.h"
#import "ReloadableListController.h"
#import "ServiceSourceDelegate.h"

#if INCLUDE_FEATURE(Ads)
#import "iAd/ADBannerView.h"
#endif

/*!
 @brief Current View.
 
 Displays the currently playing service and - if present - the current and next event.
 */
@interface CurrentViewController : ReloadableListController <UITableViewDelegate,
#if INCLUDE_FEATURE(Ads)
													ADBannerViewDelegate,
#endif
													UITableViewDataSource,
													EventSourceDelegate, ServiceSourceDelegate>
{
@private
	NSObject<EventProtocol> *_now; /*!< @brief Currently playing event. */
	NSObject<EventProtocol> *_next; /*!< @brief Next event. */
	NSObject<ServiceProtocol> *_service; /*!< @brief Current Service. */
	UITextView *_nowSummary; /*!< @brief Summary of current event. */
	UITextView *_nextSummary; /*!< @brief Summary of next event. */

	NSDateFormatter *_dateFormatter; /*!< @brief Date Formatter. */
#if INCLUDE_FEATURE(Ads)
@private
	ADBannerView *_adBannerView;
	BOOL _adBannerViewIsVisible;
#endif
}

@end
