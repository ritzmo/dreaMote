//
//  EventListController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Service;
@class FuzzyDateFormatter;
@class EventViewController;

@interface EventListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_events;
	Service *_service;
	FuzzyDateFormatter *dateFormatter;

	EventViewController *eventViewController;
}

+ (EventListController*)forService: (Service *)ourService;
- (void)addEvent:(id)event;

@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) FuzzyDateFormatter *dateFormatter;

@end
