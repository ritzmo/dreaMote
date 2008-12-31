//
//  EventTableViewCell.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Objects/EventProtocol.h"

#import "FuzzyDateFormatter.h"

// cell identifier for this custom cell
extern NSString *kEventCell_ID;

@interface EventTableViewCell : UITableViewCell {

@private	
	NSObject<EventProtocol> *_event;
	UILabel *_eventNameLabel;
	UILabel *_eventTimeLabel;
	FuzzyDateFormatter *_formatter;
}

@property (nonatomic, retain) NSObject<EventProtocol> *event;
@property (nonatomic, retain) UILabel *eventNameLabel;
@property (nonatomic, retain) UILabel *eventTimeLabel;
@property (nonatomic, retain) FuzzyDateFormatter *formatter;

@end


