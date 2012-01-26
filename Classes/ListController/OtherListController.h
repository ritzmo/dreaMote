//
//  OtherListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OtherViewProtocol.h>

@class ConfigListController;
@class MGSplitViewController;

/*!
 @brief Other Items
 
 Display list of possible actions with currently selected connection (based on RemoteConnector
 features) that are not present in the tab bar.
 */
@interface OtherListController : UIViewController <UITableViewDelegate,
													OtherViewProtocol,
													UITableViewDataSource>
{
	NSArray	*menuList; /*!< @brief Item List. */
@private
	UIViewController *_aboutDreamoteViewController; /*!< @brief Cached About View. */
	NSMutableDictionary *_aboutDictionary; /*!< @brief Dictionary describing About (Receiver) Item. */
#if IS_FULL()
	NSMutableDictionary *_autotimerDictionary; /*!< @brief Dictionary describing AutoTimer Item. */
#endif
	NSMutableDictionary *_controlDictionary; /*!< @brief Dictionary describing control item. */
	NSMutableDictionary *_epgrefreshDictionary; /*!< @brief Dictionary describing EPGRefresh Item. */
	NSMutableDictionary *_eventSearchDictionary; /*!< @brief Dictionary describing EPG Search Item. */
	NSMutableDictionary *_mediaPlayerDictionary; /*!< @brief Dictionary describing MediaPlayer Item. */
	NSMutableDictionary *_messagesDictionary; /*!< @brief Dictionary describing messages item. */
	NSMutableDictionary *_locationsDictionary; /*!< @brief Dictionary describing Locations List Item. */
	NSMutableDictionary *_recordDictionary; /*!< @brief Dictionary describing Movie List Item. */
	NSMutableDictionary *_settingsDictionary; /*!< @brief Dictionary describing settings item. */
	NSMutableDictionary *_signalDictionary; /*!< @brief Dictionary describing Signal Item. */
	NSMutableDictionary *_sleeptimerDictionary; /*!< @brief Dictionary describing SleepTimer Item. */
	NSMutableDictionary *_packageManagerDictionary; /*!< @brief Dictionary describing PackageManager Item. */
}

/*!
 @brief Table View.
 */
@property (nonatomic, strong) IBOutlet UITableView *tableView;

/*!
 @brief Parrent split view controller if available.
 */
@property (nonatomic, unsafe_unretained) MGSplitViewController *mgSplitViewController;

@end
