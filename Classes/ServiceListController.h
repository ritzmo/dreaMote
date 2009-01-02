//
//  ServiceListController.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EventListController;
@class CXMLDocument;
@protocol ServiceProtocol;

@interface ServiceListController : UIViewController <UIActionSheetDelegate,
													UITableViewDelegate, UITableViewDataSource>
{
@private
	NSObject<ServiceProtocol> *_bouquet;
	NSMutableArray *_services;
	SEL _selectCallback;
	id _selectTarget;
	BOOL _refreshServices;
	EventListController *eventListController;

	CXMLDocument *serviceXMLDoc;
}

- (void)setTarget: (id)target action: (SEL)action;

@property (nonatomic, retain) NSObject<ServiceProtocol> *bouquet;

@end
