//
//  AfterEventViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AfterEventViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSInteger _selectedItem;
	SEL _selectCallback;
	id _selectTarget;
	BOOL _showAuto;
}

+ (AfterEventViewController *)withAfterEvent: (NSInteger)afterEvent andAuto: (BOOL)showAuto;
- (void)setTarget: (id)target action: (SEL)action;

@property (assign) NSInteger selectedItem;
@property (assign) BOOL showAuto;

@end

