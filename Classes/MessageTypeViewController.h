//
//  MessageTypeViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 17.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageTypeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSInteger _selectedItem;
	SEL _selectCallback;
	id _selectTarget;
}

+ (MessageTypeViewController *)withType: (NSInteger) typeKey;

- (void)setTarget: (id)target action: (SEL)action;

@property (nonatomic) NSInteger selectedItem;

@end

