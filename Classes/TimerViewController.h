//
//  TimerViewController.h
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Timer.h"
#import "Event.h"
#import "Service.h"

@interface TimerViewController : UIViewController <UIActionSheetDelegate, UIScrollViewDelegate, UITextFieldDelegate> {
	UITextField *timerTitle;
	UITextField *timerDescription;
	UIButton *timerServiceName;
	UIButton *timerBeginString;
	UIButton *timerEndString;
	UIButton *deleteButton;
	UIResponder *lastTrackedFirstResponder;

@private
	Timer *_timer;
	Timer *_oldTimer;
	Service *_service;
	BOOL _creatingNewTimer;
	BOOL _wasActive;
}

+ (TimerViewController *)withEvent: (Event *)ourEvent;
+ (TimerViewController *)withEventAndService: (Event *)ourEvent: (Service *)ourService;
+ (TimerViewController *)withTimer: (Timer *)ourTimer;
+ (TimerViewController *)newTimer;

@property (nonatomic, retain) Timer *timer;
@property (nonatomic, retain) Timer *oldTimer;
@property (nonatomic, retain) Service *service;
@property (assign) BOOL creatingNewTimer;

@end
