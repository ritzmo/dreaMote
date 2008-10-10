//
//  EventListController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Service.h";
#import "FuzzyDateFormatter.h"

@interface EventListController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
@private
	NSArray *_events;
	Service *_service;
	FuzzyDateFormatter *dateFormatter;
}

+ (EventListController*)withEventList: (NSArray*) eventList;
+ (EventListController*)withEventListAndService: (NSArray *) eventList: (Service *)ourService;
+ (EventListController*)forService: (Service *)ourService;
- (void)reloadData;
- (void)addEvent:(id)event;

@property (nonatomic, retain) NSArray *events;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) FuzzyDateFormatter *dateFormatter;

@end
