//
//  TimerListController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TimerListController : UIViewController <UIModalViewDelegate, UITableViewDelegate, UITableViewDataSource> {
@private
	NSArray *_timers;
	NSArray *_dist;
}

- (void)addAction:(id)sender;
- (void)reloadData;

@property (nonatomic, retain) NSArray *timers;
@property (nonatomic, retain) NSArray *dist;

@end
