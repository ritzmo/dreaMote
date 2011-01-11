//
//  OtherListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Other Items
 
 Display list of possible actions with currently selected connection (based on RemoteConnector
 features) that are not present in the tab bar.
 */
@interface OtherListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	IBOutlet UITableView		*myTableView; /*!< @brief Table View. */
	NSMutableArray	*menuList; /*!< @brief Item List. */
@private
	UIViewController *_aboutDreamoteViewController; /*!< @brief Cached About View. */
	NSDictionary *_aboutDictionary; /*!< @brief Dictionary describing About (Receiver) Item. */
	NSDictionary *_eventSearchDictionary; /*!< @brief Dictionary describing EPG Search Item. */
	NSDictionary *_mediaPlayerDictionary; /*!< @brief Dictionary describing MediaPlayer Item. */
	NSDictionary *_locationsDictionary; /*!< @brief Dictionary describing Locations List Item. */
	NSDictionary *_recordDictionary; /*!< @brief Dictionary describing Movie List Item. */
	NSDictionary *_signalDictionary; /*!< @brief Dictionary describing Signal Item. */
}

/*!
 @brief Table View.
 */
@property (nonatomic, retain) UITableView *myTableView;

@end
