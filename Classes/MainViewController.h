//
//  MainViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	IBOutlet UITableView		*myTableView;
	NSMutableArray	*menuList;
@private
	UIViewController *configListController;
	UIViewController *aboutViewController;
	NSDictionary *_bouquetDictionary;
	NSDictionary *_recordDictionary;
	NSDictionary *_serviceDictionary;
	NSDictionary *_eventSearchDictionary;
}

@property (nonatomic, retain) UITableView *myTableView;

@end
