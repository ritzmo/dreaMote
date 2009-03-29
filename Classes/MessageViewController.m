//
//  MessageViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 17.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MessageViewController.h"

#import "MessageTypeViewController.h"

#import "RemoteConnector.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "DisplayCell.h"

@interface MessageViewController()
- (void)setViewMovedUp:(BOOL)movedUp;
@end

@implementation MessageViewController

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD					90.0

// the duration of the animation for the view shift
#define kVerticalOffsetAnimationDuration		0.30

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Message", @"Default title of MessageViewController");
	}
	return self;
}

- (void)dealloc
{
	[messageTextField release];
	[captionTextField release];
	[timeoutTextField release];
	[sendButton release];

	[super dealloc];
}

- (UITextField *)create_TextField
{
	UITextField *returnTextField = [[UITextField alloc] initWithFrame:CGRectZero];

	returnTextField.leftView = nil;
	returnTextField.leftViewMode = UITextFieldViewModeNever;
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
	returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [UIFont systemFontOfSize:17.0];
	returnTextField.backgroundColor = [UIColor whiteColor];
	// no auto correction support
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;

	returnTextField.keyboardType = UIKeyboardTypeDefault;
	returnTextField.returnKeyType = UIReturnKeyDone;

	// has a clear 'x' button to the right
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

	return returnTextField;
}

- (UIButton *)create_SendButton
{
	CGRect frame = CGRectMake(0.0, 0.0, kUIRowHeight, kUIRowHeight);
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
	tableView.sectionFooterHeight = 1.0;
	tableView.sectionHeaderHeight = 1.0;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];

	// Message
	messageTextField = [self create_TextField];
	messageTextField.placeholder = NSLocalizedString(@"<message text>", @"");
	messageTextField.keyboardType = UIKeyboardTypeDefault;

	// Caption
	captionTextField = [self create_TextField];
	captionTextField.placeholder = NSLocalizedString(@"<message caption>", @"");
	captionTextField.keyboardType = UIKeyboardTypeDefault;

	// Timeout
	timeoutTextField = [self create_TextField];
	timeoutTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey: kMessageTimeout];
	timeoutTextField.placeholder = NSLocalizedString(@"<message timeout>", @"");
	timeoutTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation; // XXX: we lack a better one :-)

	// Default type
	_type = 0;

	// Connect Button
	sendButton = [self create_SendButton];
	sendButton.enabled = YES;

	[self setEditing: YES animated: NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
	[super setEditing: editing animated: animated];

	if(!editing)
	{
		[messageCell stopEditing];
		[captionCell stopEditing];
		[timeoutCell stopEditing];

		typeCell.accessoryType = UITableViewCellAccessoryNone;
	}
	else
		typeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)sendMessage: (id)sender
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:4];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath
								animated: YES
								scrollPosition: UITableViewScrollPositionNone];

	NSString *failureMessage = nil;

	NSString *message = messageTextField.text;
	NSString *caption = captionTextField.text;
	NSInteger type = _type;
	NSInteger timeout = [timeoutTextField.text integerValue];

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
	else if(![[RemoteConnectorObject sharedRemoteConnector] sendMessage:
															   message :caption :type :timeout])
		failureMessage = NSLocalizedString(@"Could not send message.", @"");

	if(failureMessage != nil)
	{
		UIAlertView *notification = [[UIAlertView alloc]
									 initWithTitle:NSLocalizedString(@"Error", @"")
									 message:failureMessage
									 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
		[notification release];
	}

	[(UITableView *)self.view deselectRowAtIndexPath: indexPath animated: YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)typeSelected: (NSNumber *) newType
{
	if(newType == nil)
		return;

	_type = [newType integerValue];

	typeCell.text = [[RemoteConnectorObject sharedRemoteConnector] getMessageTitle: _type];
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
	if(section == 1)
	{
		if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageCaption])
			return 0;
	}
	else if(section == 2)
	{
		if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageTimeout])
			return 0;
	}
	else if(section == 3)
	{
		if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageType])
			return 0;
	}
	return 1;
}


// as some rows are hidden we want to hide the gap created by empty sections by
// resizing the header fields.
//
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if(section == 0 || section == 4)
		return 34.0;
	
	if(section == 1)
	{
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageCaption])
			return 34.0;
	}
	else if(section == 2)
	{
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageTimeout])
			return 34.0;
	}
	else if(section == 3)
	{
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageType])
			return 34.0;
	}

	return 0.0;
}

// determine the adjustable height of a row. these are determined by the sections and if a
// section is set to be hidden the row size is reduced to 0.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	if(section == 0 || section == 4)
		return kUIRowHeight;

	if(section == 1)
	{
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageCaption])
			return kUIRowHeight;
	}
	else if(section == 2)
	{
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageTimeout])
			return kUIRowHeight;
	}
	else if(section == 3)
	{
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesMessageType])
			return kUIRowHeight;
	}

	return 0.0;
}

// utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell to be used on a given section.
//
- (UITableViewCell *)obtainTableCellForSection:(UITableView *)tableView: (NSInteger)section
{
	static NSString *kVanilla_ID = @"Vanilla_ID";
	
	UITableViewCell *cell = nil;
	
	switch (section) {
		case 0:
		case 1:
		case 2:
			cell = [tableView dequeueReusableCellWithIdentifier:kCellTextField_ID];
			if(cell == nil)
				cell = [[[CellTextField alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextField_ID] autorelease];
			((CellTextField *)cell).delegate = self;	// so we can detect when cell editing starts
			break;
		case 3:
			cell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
			if (cell == nil) 
				cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

			cell.textAlignment = UITextAlignmentLeft;
			cell.textColor = [UIColor blackColor];
			cell.font = [UIFont systemFontOfSize:kTextViewFontSize];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			break;
		case 4:
			cell = [tableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(cell == nil)
				cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
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
	NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = [self obtainTableCellForSection: tableView: section];

	// we are creating a new cell, setup its attributes
	switch(section)
	{
		case 0:
			((CellTextField *)sourceCell).view = messageTextField;
			messageCell = (CellTextField *)sourceCell;
			break;
		case 1:
			((CellTextField *)sourceCell).view = captionTextField;
			captionCell = (CellTextField *)sourceCell;
			break;
		case 2:
			((CellTextField *)sourceCell).view = timeoutTextField;
			timeoutCell = (CellTextField *)sourceCell;
			break;
		case 3:
			if(self.editing)
				sourceCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

			sourceCell.text = [[RemoteConnectorObject sharedRemoteConnector] getMessageTitle: _type];

			typeCell = sourceCell;
			break;
		case 4:
			((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Send", @"");
			((DisplayCell *)sourceCell).view = sendButton;
			break;
		default:
			break;
	}

	return sourceCell;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	if(self.editing && section == 3)
	{
		MessageTypeViewController *targetViewController = [MessageTypeViewController withType: _type];
		[targetViewController setTarget: self action: @selector(typeSelected:)];
		[self.navigationController pushViewController: targetViewController animated: YES];
		[targetViewController release];
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
	if (![cell isEqual: messageCell])
		[messageCell stopEditing];
	if (![cell isEqual: captionCell])
		[captionCell stopEditing];
	if (![cell isEqual: timeoutCell])
		[timeoutCell stopEditing];

	return self.editing;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	if([cell isEqual: captionCell] || [cell isEqual: timeoutCell])
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
	if(timeoutCell.isInlineEditing)
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

	[[NSUserDefaults standardUserDefaults] setValue:timeoutTextField.text forKey: kMessageTimeout];
}

@end
