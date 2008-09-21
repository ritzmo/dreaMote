//
//  TimerListController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Timer.h"

@interface TimerListController : UIViewController <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource> {
@private
	NSMutableArray *_timers;
	NSInteger dist[kTimerStateMax];
}

- (void)addAction:(id)sender;
- (void)reloadData;

@property (nonatomic, retain) NSMutableArray *timers;

@end
