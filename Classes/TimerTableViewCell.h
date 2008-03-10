//
//  TimerTableViewCell.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Timer.h"

@interface TimerTableViewCell : UITableViewCell {

@private	
	Timer *_timer;
}

@property (nonatomic, retain) Timer *timer;

@end
