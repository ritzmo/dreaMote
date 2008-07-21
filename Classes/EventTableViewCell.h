//
//  EventTableViewCell.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event.h"

@interface EventTableViewCell : UITableViewCell {

@private	
	Event *_event;
	UILabel *_eventNameLabel;
	UILabel *_eventTimeLabel;
}

@property (nonatomic, retain) Event *event;
@property (nonatomic, retain) UILabel *eventNameLabel;
@property (nonatomic, retain) UILabel *eventTimeLabel;

@end


