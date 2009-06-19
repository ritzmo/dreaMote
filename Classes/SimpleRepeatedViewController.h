//
//  SimpleRepeatedViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 19.06.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SimpleRepeatedViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	NSInteger _repeated;
	SEL _selectCallback;
	id _selectTarget;
}

+ (SimpleRepeatedViewController *)withRepeated: (NSInteger)repeated;
- (void)setTarget: (id)target action: (SEL)action;

@property (assign) NSInteger repeated;

@end

