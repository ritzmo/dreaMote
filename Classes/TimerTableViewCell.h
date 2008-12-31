//
//  TimerTableViewCell.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/Generic/Timer.h"

#import "FuzzyDateFormatter.h"

// cell identifier for this custom cell
extern NSString *kTimerCell_ID;

@interface TimerTableViewCell : UITableViewCell
{
@private	
	Timer *_timer;
	UILabel *_serviceNameLabel;
	UILabel *_timerNameLabel;
	UILabel *_timerTimeLabel;
	FuzzyDateFormatter *_formatter;
}

@property (nonatomic, retain) Timer *timer;
@property (nonatomic, retain) UILabel *serviceNameLabel;
@property (nonatomic, retain) UILabel *timerNameLabel;
@property (nonatomic, retain) UILabel *timerTimeLabel;
@property (nonatomic, retain) FuzzyDateFormatter *formatter;

@end
