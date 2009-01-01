//
//  TimerViewController.h
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Service;

#import "Objects/EventProtocol.h"
#import "Objects/TimerProtocol.h"
#import "CellTextField.h"

@class ServiceListController;
@class AfterEventViewController;
@class DatePickerController;

@interface TimerViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate,
													UITableViewDelegate, UITableViewDataSource,
													EditableTableViewCellDelegate>
{
@private
	UITextField *timerTitle;
	CellTextField *timerTitleCell;
	UITextField *timerDescription;
	CellTextField *timerDescriptionCell;
	UIButton *timerServiceName;
	UITableViewCell *timerServiceNameCell;
	UIButton *timerBegin;
	UITableViewCell *timerBeginCell;
	UIButton *timerEnd;
	UITableViewCell *timerEndCell;
	UISwitch *timerEnabled;
	UISwitch *timerJustplay;
	UITableViewCell *afterEventCell;
	
	NSObject<TimerProtocol> *_timer;
	NSObject<TimerProtocol> *_oldTimer;
	BOOL _creatingNewTimer;
	BOOL _shouldSave;

	ServiceListController *serviceListController;
	AfterEventViewController *afterEventViewController;
	DatePickerController *datePickerController;
}

+ (TimerViewController *)withEvent: (NSObject<EventProtocol> *)ourEvent;
+ (TimerViewController *)withEventAndService: (NSObject<EventProtocol> *)ourEvent: (Service *)ourService;
+ (TimerViewController *)withTimer: (NSObject<TimerProtocol> *)ourTimer;
+ (TimerViewController *)newTimer;

@property (nonatomic, retain) NSObject<TimerProtocol> *timer;
@property (nonatomic, retain) NSObject<TimerProtocol> *oldTimer;
@property (assign) BOOL creatingNewTimer;

@end
