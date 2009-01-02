//
//  BouquetListController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ServiceListController;
@class CXMLDocument;

@interface BouquetListController : UIViewController <UIActionSheetDelegate,
													UITableViewDelegate, UITableViewDataSource>
{
@private
	NSMutableArray *_bouquets;
	SEL _selectCallback;
	id _selectTarget;
	BOOL _refreshBouquets;
	ServiceListController *serviceListController;

	CXMLDocument *bouquetXMLDoc;
}

- (void)setTarget: (id)target action: (SEL)action;

@end
