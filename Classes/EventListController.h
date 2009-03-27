//
//  EventListController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ServiceProtocol;
@class FuzzyDateFormatter;
@class EventViewController;
@class CXMLDocument;

@interface EventListController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@protected
	NSMutableArray *_events;
	NSObject<ServiceProtocol> *_service;
	FuzzyDateFormatter *dateFormatter;

	CXMLDocument *eventXMLDoc;
	EventViewController *eventViewController;
}

+ (EventListController*)forService: (NSObject<ServiceProtocol> *)ourService;
- (void)addEvent:(id)event;

@property (nonatomic, retain) NSObject<ServiceProtocol> *service;
@property (nonatomic, retain) FuzzyDateFormatter *dateFormatter;

@end
