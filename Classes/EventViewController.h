//
//  EventViewController.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Event.h"

@interface EventViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate>
{
	UITextView *myTextView;
	Event *_event;
}

+ (EventViewController*)withEvent: (Event*) newEvent;

@property (nonatomic, retain) Event *event;

@end
