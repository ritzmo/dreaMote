//
//  MessageViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 17.10.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "MessageViewController.h"

#import "Constants.h"
#import "RemoteConnector.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

#import "SimpleSingleSelectionListController.h"

#import "DisplayCell.h"

#import <Objects/Generic/Result.h>

/*!
 @brief Private functions of MessageViewController.
 */
@interface MessageViewController()
/*!
 @brief Animate View up or down.
 Animate the entire view up or down, to prevent the keyboard from covering the text field.
 
 @param movedUp YES if moving down again.
 */
- (void)setViewMovedUp:(BOOL)movedUp;

/*!
 @brief send message
 @param sender ui element
 */
- (void)sendMessage: (id)sender;
@end

@implementation MessageViewController

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD					90

// the duration of the animation for the view shift
#define kVerticalOffsetAnimationDuration		(CGFloat)0.30

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Message", @"Default title of MessageViewController");
		_typeCell = nil;
	}
	return self;
}

- (void)dealloc
{
	UnsetCellAndDelegate(_messageCell);
	UnsetCellAndDelegate(_captionCell);
	UnsetCellAndDelegate(_timeoutCell);
	_typeCell = nil;
	SafeRetainAssign(_messageTextField, nil);
	SafeRetainAssign(_captionTextField, nil);
	SafeRetainAssign(_timeoutTextField, nil);
	SafeDestroyButton(_sendButton);
}

- (UITextField *)allocTextField
{
	UITextField *returnTextField = [[UITextField alloc] initWithFrame:CGRectZero];

	returnTextField.leftView = nil;
	returnTextField.leftViewMode = UITextFieldViewModeNever;
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
	returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [UIFont systemFontOfSize:kTextFieldFontSize];
	returnTextField.backgroundColor = [UIColor whiteColor];
	// no auto correction support
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;

	returnTextField.keyboardType = UIKeyboardTypeDefault;
	returnTextField.returnKeyType = UIReturnKeyDone;

	// has a clear 'x' button to the right
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

	return returnTextField;
}

- (UIButton *)allocSendButton
{
	const CGRect frame = CGRectMake(0, 0, kUIRowHeight, kUIRowHeight);
	UIButton *button = [[UIButton alloc] initWithFrame: frame];
	UIImage *image = [UIImage imageNamed:@"mail-forward.png"];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(sendMessage:)
				forControlEvents:UIControlEventTouchUpInside];

	return button;
}

- (void)loadView
{
	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.sectionFooterHeight = 1;
	tableView.sectionHeaderHeight = 1;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;

	// Message
	_messageTextField = [self allocTextField];
	_messageTextField.placeholder = NSLocalizedString(@"<message text>", @"");
	_messageTextField.keyboardType = UIKeyboardTypeDefault;

	// Caption
	_captionTextField = [self allocTextField];
	_captionTextField.placeholder = NSLocalizedString(@"<message caption>", @"");
	_captionTextField.keyboardType = UIKeyboardTypeDefault;

	// Timeout
	_timeoutTextField = [self allocTextField];
	_timeoutTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey: kMessageTimeout];
	_timeoutTextField.placeholder = NSLocalizedString(@"<message timeout>", @"");
	_timeoutTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation; // NOTE: we lack a better one :-)

	// Default type
	_type = 0;

	// Connect Button
	_sendButton = [self allocSendButton];
	_sendButton.enabled = YES;

	[self setEditing: YES animated: NO];
}

- (void)viewDidUnload
{
	UnsetCellAndDelegate(_messageCell);
	UnsetCellAndDelegate(_captionCell);
	UnsetCellAndDelegate(_timeoutCell);
	_typeCell = nil;
	SafeRetainAssign(_messageTextField, nil);
	SafeRetainAssign(_captionTextField, nil);
	SafeRetainAssign(_timeoutTextField, nil);
	SafeDestroyButton(_sendButton);

	[super viewDidUnload];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];

	if(!editing)
	{
		[_messageCell stopEditing];
		[_captionCell stopEditing];
		[_timeoutCell stopEditing];

		if(_typeCell)
			_typeCell.accessoryType = UITableViewCellAccessoryNone;
	}
	else if(_typeCell)
		_typeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)sendMessage: (id)sender
{
	NSString *failureMessage = nil;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:4];
	NSString *message = _messageTextField.text;
	NSString *caption = _captionTextField.text;
	const NSInteger type = _type;
	const NSInteger timeout = [_timeoutTextField.text integerValue];

	[(UITableView *)self.view selectRowAtIndexPath: indexPath
								animated: YES
								scrollPosition: UITableViewScrollPositionNone];

	// XXX: we could also join these messages
	if(message == nil || [message isEqualToString: @""])
		failureMessage = NSLocalizedString(@"Message cannot be empty.", @"");
	else if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageCaption]
			&& (caption == nil || [caption isEqualToString: @""]))
		failureMessage = NSLocalizedString(@"Caption cannot be empty.", @"");
	else if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageTimeout]
			&& timeout == 0)
		failureMessage = NSLocalizedString(@"Please provide a valid timeout interval.", @"");
	else if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageType]
			&& _type >= [[RemoteConnectorObject sharedRemoteConnector] getMaxMessageType])
		failureMessage = NSLocalizedString(@"Invalid message type.", @"");
	else
	{
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] sendMessage:
															message :caption :type :timeout];
		if(!result.result)
		{
			UIAlertView *notification = [[UIAlertView alloc]
										 initWithTitle:NSLocalizedString(@"Could not send message.", @"")
										 message:result.resulttext
										 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[notification show];
		}
	}

	if(failureMessage != nil)
	{
		UIAlertView *notification = [[UIAlertView alloc]
									 initWithTitle:NSLocalizedString(@"Error", @"")
									 message:failureMessage
									 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
	}

	[(UITableView *)self.view deselectRowAtIndexPath: indexPath animated: YES];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// We always have 5 sections, but not all of them have content (see MovieViewController)
	return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:
			return NSLocalizedString(@"Text", @"");
		case 1:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageCaption])
				return NSLocalizedString(@"Caption", @"");
			return nil;
		case 2:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageTimeout])
				return NSLocalizedString(@"Timeout", @"");
			return nil;
		case 3:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageType])
				return NSLocalizedString(@"Type", @"");
			return nil;
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case 1:
			if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageCaption])
				return 0;
			break;
		case 2:
			if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageTimeout])
				return 0;
			break;
		case 3:
			if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageType])
				return 0;
			break;
		default:
			break;
	}
	return 1;
}

// as some rows are hidden we want to hide the gap created by empty sections by
// resizing the header fields.
//
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:
		case 4:
			return 34;
		case 1:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageCaption])
				return 34;
			break;
		case 2:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageTimeout])
				return 34;
			break;
		case 3:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageType])
				return 34;
			break;
		default:
			break;
	}

	return 0;
}

// determine the adjustable height of a row. these are determined by the sections and if a
// section is set to be hidden the row size is reduced to 0.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger section = indexPath.section;
	switch(section)
	{
		case 0:
		case 4:
			return kUIRowHeight;
		case 1:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageCaption])
				return kUIRowHeight;
			break;
		case 2:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageTimeout])
				return kUIRowHeight;
			break;
		case 3:
			if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageType])
				return kUIRowHeight;
			break;
		default:
			break;
	}

	return 0;
}

// utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell to be used on a given section.
//
- (UITableViewCell *)obtainTableCellForSection:(UITableView *)tableView: (NSInteger)section
{
	UITableViewCell *cell = nil;
	
	switch (section) {
		case 0:
		case 1:
		case 2:
			cell = [CellTextField reusableTableViewCellInView:tableView withIdentifier:kCellTextField_ID];
			((CellTextField *)cell).delegate = self;	// so we can detect when cell editing starts
			break;
		case 3:
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];

			TABLEVIEWCELL_ALIGN(cell) = UITextAlignmentLeft;
			TABLEVIEWCELL_COLOR(cell) = [UIColor blackColor];
			TABLEVIEWCELL_FONT(cell) = [UIFont systemFontOfSize:kTextViewFontSize];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			break;
		case 4:
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		default:
			break;
	}
	
	return cell;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = [self obtainTableCellForSection: tableView: section];

	// we are creating a new cell, setup its attributes
	switch(section)
	{
		case 0:
			((CellTextField *)sourceCell).view = _messageTextField;
			_messageCell = (CellTextField *)sourceCell;
			break;
		case 1:
			((CellTextField *)sourceCell).view = _captionTextField;
			_captionCell = (CellTextField *)sourceCell;
			break;
		case 2:
			((CellTextField *)sourceCell).view = _timeoutTextField;
			_timeoutCell = (CellTextField *)sourceCell;
			break;
		case 3:
			if(self.editing)
				sourceCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

			TABLEVIEWCELL_TEXT(sourceCell) = [[RemoteConnectorObject sharedRemoteConnector] getMessageTitle: _type];

			_typeCell = sourceCell;
			break;
		case 4:
			((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Send", @"");
			((DisplayCell *)sourceCell).view = _sendButton;
			break;
		default:
			break;
	}

	return sourceCell;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger section = indexPath.section;
	if(self.editing && section == 3)
	{
		const BOOL isIpad = IS_IPAD();
		NSMutableArray *messages = [NSMutableArray array];
		NSUInteger i = 0;
		const NSUInteger maxMessageType = [[RemoteConnectorObject sharedRemoteConnector] getMaxMessageType];
		for(; i < maxMessageType; ++i)
		{
			[messages addObject:[[RemoteConnectorObject sharedRemoteConnector] getMessageTitle:i]];
		}

		SimpleSingleSelectionListController *targetViewController = [SimpleSingleSelectionListController withItems:messages andSelection:_type andTitle:NSLocalizedString(@"Message Type", @"Default title of MessageTypeViewController")];
		targetViewController.callback = ^(NSUInteger selection, BOOL isFinal)
		{
			if(!isIpad && !isFinal)
				return NO; // iPhone only handles final calls
			_type = selection;

			_typeCell.textLabel.text = [[RemoteConnectorObject sharedRemoteConnector] getMessageTitle: _type];
			if(isIpad)
				[self dismissModalViewControllerAnimated:YES];
			return YES;
		};
		if(isIpad)
		{
			UIViewController *navController = [[UINavigationController alloc] initWithRootViewController:targetViewController];
			navController.modalPresentationStyle = targetViewController.modalPresentationStyle;
			navController.modalPresentationStyle = targetViewController.modalPresentationStyle;
			[self.navigationController presentModalViewController:navController animated:YES];
		}
		else
			[self.navigationController pushViewController: targetViewController animated: YES];
	}
	else if(section == 4)
	{
		[self sendMessage: nil];
	}

	// We don't want any actual response :-)
	return nil;
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management

- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	// notify other cells to end editing
	if (![cell isEqual: _messageCell])
		[_messageCell stopEditing];
	if (![cell isEqual: _captionCell])
		[_captionCell stopEditing];
	if (![cell isEqual: _timeoutCell])
		[_timeoutCell stopEditing];

	return self.editing;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	if([cell isEqual: _captionCell] || [cell isEqual: _timeoutCell])
	{
		// Restore the position of the main view if it was animated to make room for the keyboard.
		if(self.view.frame.origin.y < 0)
			[self setViewMovedUp:NO];
	}
}

// Animate the entire view up or down, to prevent the keyboard from covering the author field.
- (void)setViewMovedUp:(BOOL)movedUp
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration: kVerticalOffsetAnimationDuration];

	// Make changes to the view's frame inside the animation block. They will be animated instead
	// of taking place immediately.
	CGRect rect = self.view.frame;
	if (movedUp)
	{
		// If moving up, not only decrease the origin but increase the height so the view 
		// covers the entire screen behind the keyboard.
		rect.origin.y -= kOFFSET_FOR_KEYBOARD;
		rect.size.height += kOFFSET_FOR_KEYBOARD;
	}
	else
	{
		// If moving down, not only increase the origin but decrease the height.
		rect.origin.y += kOFFSET_FOR_KEYBOARD;
		rect.size.height -= kOFFSET_FOR_KEYBOARD;
	}
	self.view.frame = rect;

	[UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notif
{
	// The keyboard will be shown. If the user is editing the caption or timeout adjust the
	// display so that the field will not be covered by the keyboard.
	if(_timeoutCell.isInlineEditing)
	{
		if(self.view.frame.origin.y >= 0)
			[self setViewMovedUp:YES];
	}
	else if(self.view.frame.origin.y < 0)
		[self setViewMovedUp:NO];
}

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
	// watch the keyboard so we can adjust the user interface if necessary.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
												 name:UIKeyboardWillShowNotification object:self.view.window];

	[(UITableView *)self.view reloadData];

	[super viewWillAppear: animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// unregister for keyboard notifications while not visible.
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 

	[super viewWillDisappear: animated];

	[[NSUserDefaults standardUserDefaults] setValue:_timeoutTextField.text forKey: kMessageTimeout];
}

@end
