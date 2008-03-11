//
//  EventViewController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Event.h"

@interface EventViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UITextFieldDelegate>
{
	UITextView *myTextView;
	Event *_event;
}

+ (UILabel *)fieldLabelWithFrame:(CGRect)frame title:(NSString *)title;
+ (EventViewController*)withEvent: (Event*) newEvent;

@property (nonatomic, retain) Event *event;

@end
