//
//  SimpleRepeatedViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 19.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "SimpleRepeatedViewController.h"

#import "Constants.h"
#import "UITableViewCell+EasyInit.h"

#import <TableViewCell/BaseTableViewCell.h>

#import <Objects/TimerProtocol.h>
#import <Objects/Generic/Timer.h>

@interface SimpleRepeatedViewController()
- (IBAction)doneAction:(id)sender;
@end

@implementation SimpleRepeatedViewController

@synthesize callback;
@synthesize tableView = _tableView;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Repeated", @"Default title of SimpleRepeatedViewController");

		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	return self;
}

/* create new SimpleRepeatedViewController instance with given flags */
+ (SimpleRepeatedViewController *)withRepeated: (NSInteger)repeated andCount:(NSInteger)repcount
{
	SimpleRepeatedViewController *simpleRepeatedViewController = [[SimpleRepeatedViewController alloc] init];
	simpleRepeatedViewController.repeated = repeated;
	simpleRepeatedViewController.repcount = repcount;

	return simpleRepeatedViewController;
}

- (NSInteger)repeated
{
	return _repeated;
}

- (void)setRepeated:(NSInteger)newRepeated
{
	_repeated = newRepeated;
	[_tableView reloadData];
}

- (NSInteger)repcount
{
	return _repcount;
}

- (void)setRepcount:(NSInteger)newRepcount
{
	_repcount = newRepcount;
	_repcountField.text = [NSString stringWithFormat:@"%d", _repcount];
}

- (BOOL)isSimple
{
	return _isSimple;
}

- (void)setIsSimple:(BOOL)isSimple
{
	if(_isSimple == isSimple) return;
	_isSimple = isSimple;
	[_tableView reloadData];
}

/* layout */
- (void)loadView
{
	// create and configure the table view
	_tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kUIRowHeight;
	_tableView.autoresizesSubviews = YES;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	if(IS_IPAD())
		_tableView.backgroundView = [[UIView alloc] init];

	self.view = _tableView;

	// repeat count
	_repcountField = [[UITextField alloc] initWithFrame:CGRectZero];
	_repcountField.leftView = nil;
	_repcountField.leftViewMode = UITextFieldViewModeNever;
	_repcountField.borderStyle = UITextBorderStyleRoundedRect;
	_repcountField.textColor = [UIColor blackColor];
	_repcountField.font = [UIFont systemFontOfSize:kTextFieldFontSize];
	_repcountField.backgroundColor = [UIColor whiteColor];
	// no auto correction support
	_repcountField.autocorrectionType = UITextAutocorrectionTypeNo;
	// NOTE: number pad does not have dismiss button on the iphone...
	if(IS_IPAD())
		_repcountField.keyboardType = UIKeyboardTypeNumberPad;
	_repcountField.returnKeyType = UIReturnKeyDone;
	// has a clear 'x' button to the right
	_repcountField.clearButtonMode = UITextFieldViewModeWhileEditing;
	_repcountField.placeholder = NSLocalizedString(@"0 = unlimited", @"Comment for repeat count in neutrino");
	_repcountField.text = [NSString stringWithFormat:@"%d", _repcount];

	if(IS_IPAD())
	{
		UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
		self.navigationItem.rightBarButtonItem = barButtonItem;
	}

	[self theme];
}

- (void)viewDidUnload
{
	_repcountField = nil;
	 // references _repcountField
	_repcountCell = nil;
	_tableView = nil;

	[super viewDidUnload];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

/* done editing */
- (IBAction)doneAction:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UITableView delegates

/* header */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if(_isSimple)
		return 1;
	if((_repeated & neutrinoTimerRepeatWeekdays) == neutrinoTimerRepeatWeekdays)
		return 3;
	return 2;
}

/* rows in section */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 0 || section == 2) // the same in simple and non-simple
		return 7;
	else //if(section == 1)
		return 1;
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;

	if(!_isSimple)
	{
		if(indexPath.section == 0)
		{
			cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
			// we are creating a new cell, setup its attributes
			switch(indexPath.row)
			{
				case 0:
					cell.textLabel.text = NSLocalizedString(@"Never", @"Repeated");
					if(_repeated == neutrinoTimerRepeatNever) cell.accessoryType = UITableViewCellAccessoryCheckmark;
					else cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case 1:
					cell.textLabel.text = NSLocalizedString(@"Daily", @"Repeated");
					if(_repeated == neutrinoTimerRepeatDaily) cell.accessoryType = UITableViewCellAccessoryCheckmark;
					else cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case 2:
					cell.textLabel.text = NSLocalizedString(@"Weekly", @"Repeated");
					if(_repeated == neutrinoTimerRepeatWeekly) cell.accessoryType = UITableViewCellAccessoryCheckmark;
					else cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case 3:
					cell.textLabel.text = NSLocalizedString(@"2-weekly", @"Repeated");
					if(_repeated == neutrinoTimerRepeatBiweekly) cell.accessoryType = UITableViewCellAccessoryCheckmark;
					else cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case 4:
					cell.textLabel.text = NSLocalizedString(@"4-weekly", @"Repeated");
					if(_repeated == neutrinoTimerRepeatFourweekly) cell.accessoryType = UITableViewCellAccessoryCheckmark;
					else cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case 5:
					cell.textLabel.text = NSLocalizedString(@"Monthly", @"Repeated");
					if(_repeated == neutrinoTimerRepeatMonthly) cell.accessoryType = UITableViewCellAccessoryCheckmark;
					else cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				case 6:
					cell.textLabel.text = NSLocalizedString(@"Other", @"Repeated");
					if(_repeated & neutrinoTimerRepeatWeekdays) cell.accessoryType = UITableViewCellAccessoryCheckmark;
					else cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				default:
					break;
			}
		}
		else if (indexPath.section == 1)
		{
			if(_repcountCell == nil)
			{
				_repcountCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
				_repcountCell.view = _repcountField;
				_repcountCell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
				_repcountCell.textLabel.text = NSLocalizedString(@"Repetitions", @"Cell Label of repeat count in Neutrino");
				_repcountCell.fixedWidth = 100.0f;
			}
			cell = _repcountCell;
		}
	}

	if(_isSimple || ((_repeated & neutrinoTimerRepeatWeekdays) > 0 && indexPath.section == 2))
	{
		cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
		// we are creating a new cell, setup its attributes
		switch(indexPath.row)
		{
			case 0:
				cell.textLabel.text = NSLocalizedString(@"Monday", @"");
				break;
			case 1:
				cell.textLabel.text = NSLocalizedString(@"Tuesday", @"");
				break;
			case 2:
				cell.textLabel.text = NSLocalizedString(@"Wednesday", @"");
				break;
			case 3:
				cell.textLabel.text = NSLocalizedString(@"Thursday", @"");
				break;
			case 4:
				cell.textLabel.text = NSLocalizedString(@"Friday", @"");
				break;
			case 5:
				cell.textLabel.text = NSLocalizedString(@"Saturday", @"");
				break;
			case 6:
				cell.textLabel.text = NSLocalizedString(@"Sunday", @"");
				break;
			default:
				break;
		}

		if(_isSimple)
		{
			if(_repeated & (1 << indexPath.row))
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			else
				cell.accessoryType = UITableViewCellAccessoryNone;
		}
		else
		{
			if(_repeated & (1 << (indexPath.row + 8)))
			   cell.accessoryType = UITableViewCellAccessoryCheckmark;
			else
			   cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}

	[[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
	return cell;
}

/* select row */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];

	[tableView deselectRowAtIndexPath: indexPath animated: YES];

	if(_isSimple)
	{
		// Already selected, deselect
		if(_repeated & (1 << indexPath.row))
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
			_repeated &= ~(1 << indexPath.row);
		}
		// Not selected, select
		else
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			_repeated |= (1 << indexPath.row);
		}
	}
	else
	{
		if(indexPath.section == 0)
		{
			switch(indexPath.row)
			{
				case 0: _repeated = neutrinoTimerRepeatNever; break;
				case 1: _repeated = neutrinoTimerRepeatDaily; break;
				case 2: _repeated = neutrinoTimerRepeatWeekly; break;
				case 3: _repeated = neutrinoTimerRepeatBiweekly; break;
				case 4: _repeated = neutrinoTimerRepeatFourweekly; break;
				case 5: _repeated = neutrinoTimerRepeatMonthly; break;
				case 6:
					if((_repeated & neutrinoTimerRepeatWeekdays) != neutrinoTimerRepeatWeekdays)
						_repeated = neutrinoTimerRepeatWeekdays;
					break;
				default: break;
			}
			[_tableView reloadData];
		}
		else if(indexPath.section == 2)
		{
			NSInteger row = indexPath.row + 8;
			if(_repeated & (1 << row))
			{
				cell.accessoryType = UITableViewCellAccessoryNone;
				_repeated &= ~(1 << row);
			}
			else
			{
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				_repeated |= (1 << row);
			}
		}
	}
}

#pragma mark - UIViewController delegate methods

/* about to disapper */
- (void)viewWillDisappear:(BOOL)animated
{
	simplerepeated_callback_t call = callback;
	callback = nil;
	if(call)
		call(_repeated, [_repcountField.text integerValue]); 
}

@end
