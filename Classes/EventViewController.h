//
//  EventViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Objects/EventProtocol.h"
#import "Objects/ServiceProtocol.h"

@class CXMLDocument;
@class FuzzyDateFormatter;

@interface EventViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_similarEvents;
	NSObject<EventProtocol> *_event;
	NSObject<ServiceProtocol> *_service;
	BOOL _similarFetched;
	BOOL _isSearch;

	FuzzyDateFormatter *dateFormatter;
	CXMLDocument *eventXMLDoc;
}

+ (EventViewController *)withEventAndService: (NSObject<EventProtocol> *) newEvent: (NSObject<ServiceProtocol> *)newService;
+ (EventViewController *)withEvent: (NSObject<EventProtocol> *) newEvent;

@property (nonatomic, retain) NSObject<EventProtocol> *event;
@property (nonatomic, retain) NSObject<ServiceProtocol> *service;
@property (nonatomic) BOOL search;

@end
