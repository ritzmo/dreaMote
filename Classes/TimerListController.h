//
//  TimerListController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Timer.h"
#import "FuzzyDateFormatter.h"

@interface TimerListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_timers;
	NSInteger dist[kTimerStateMax];
	FuzzyDateFormatter *dateFormatter;
}

- (void)reloadData;

@property (nonatomic, retain) NSMutableArray *timers;
@property (nonatomic, retain) FuzzyDateFormatter *dateFormatter;

@end
