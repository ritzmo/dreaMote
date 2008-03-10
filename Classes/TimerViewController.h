//
//  TimerViewController.h
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Timer.h"

@interface TimerViewController : UIViewController <UIScrollViewDelegate, UITextFieldDelegate> {
	UITextField *timerTitle;
	UIResponder *lastTrackedFirstResponder;

@private
	Timer *_timer;
	BOOL _creatingNewTimer;
}

+ (TimerViewController *)withTimer: (Timer *)ourTimer;
+ (TimerViewController *)newTimer;

@property (nonatomic, retain) Timer *timer;
@property (assign) BOOL creatingNewTimer;

@end
