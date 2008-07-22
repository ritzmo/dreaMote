//
//  EventListController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Service.h";

@interface EventListController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
@private
	NSMutableArray *_events;
	Service *_service;
	int _eventCount;
}

+ (EventListController*)withEventList: (NSArray*) eventList;
+ (EventListController*)withEventListAndService: (NSArray *) eventList: (Service *)ourService;
- (void)reloadData;
- (void)addEvent:(id)event;

@property (nonatomic, retain) NSMutableArray *events;
@property (nonatomic, retain) Service *service;
@property (nonatomic) int eventCount;

@end
