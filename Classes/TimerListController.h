//
//  TimerListController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerListController : UIViewController <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource> {
@private
	NSMutableArray *_timers;
	int dist[4];
}

- (void)addAction:(id)sender;
- (void)reloadData;

@property (nonatomic, retain) NSMutableArray *timers;

@end
