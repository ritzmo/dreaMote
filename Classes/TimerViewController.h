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

@interface TimerViewController : UIViewController <UIScrollViewDelegate, UITextFieldDelegate> {
	UITextField *timerTitle;
	UITextField *timerDescription;
	UITextField *timerServiceName;
	UITextField *timerBeginString;
	UITextField *timerEndString;
	UIResponder *lastTrackedFirstResponder;

@private
	Timer *_timer;
	Service *_service;
	NSDate *_begin;
	NSDate *_end;
	BOOL _creatingNewTimer;
}

+ (TimerViewController *)withEvent: (Event *)ourEvent;
+ (TimerViewController *)withEventAndService: (Event *)ourEvent: (Service *)ourService;
+ (TimerViewController *)withTimer: (Timer *)ourTimer;
+ (TimerViewController *)newTimer;

@property (nonatomic, retain) Timer *timer;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) NSDate *begin;
@property (nonatomic, retain) NSDate *end;
@property (assign) BOOL creatingNewTimer;

@end
