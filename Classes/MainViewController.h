//
//  MainViewController.h
//  Untitled
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
}

@property (nonatomic, retain) UITableView *myTableView;

@end
