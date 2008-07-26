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

#import "CellTextField.h"
#import "DisplayCell.h"

@interface TimerViewController : UIViewController <UIActionSheetDelegate, UIScrollViewDelegate,
													UITextFieldDelegate, UITableViewDelegate,
													UITableViewDataSource, EditableTableViewCellDelegate>
{
	UITableView *myTableView;
	UITextField *timerTitle;
	CellTextField *timerTitleCell;
	UITextField *timerDescription;
	CellTextField *timerDescriptionCell;
	UIButton *timerServiceName;
	DisplayCell *timerServiceNameCell;
	UIButton *timerBegin;
	DisplayCell *timerBeginCell;
	UIButton *timerEnd;
	DisplayCell *timerEndCell;
	UIButton *deleteButton;

@private
	Timer *_timer;
	Timer *_oldTimer;
	Service *_service;
	BOOL _creatingNewTimer;
	BOOL _shouldSave;
}

+ (TimerViewController *)withEvent: (Event *)ourEvent;
+ (TimerViewController *)withEventAndService: (Event *)ourEvent: (Service *)ourService;
+ (TimerViewController *)withTimer: (Timer *)ourTimer;
+ (TimerViewController *)newTimer;

@property (nonatomic, retain) Timer *timer;
@property (nonatomic, retain) Timer *oldTimer;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) UITableView *myTableView;
@property (assign) BOOL creatingNewTimer;

@end
