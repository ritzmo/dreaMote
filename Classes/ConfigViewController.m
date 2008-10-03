//
//  ConfigViewController.m
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ConfigViewController.h"

#import "RemoteConnector.h"
#import "RemoteConnectorObject.h"
#import "ConnectorViewController.h"
#import "Constants.h"

@interface ConfigViewController()
- (void)setViewMovedUp:(BOOL)movedUp;
@end

@implementation ConfigViewController

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD					120.0

// the duration of the animation for the view shift
#define kVerticalOffsetAnimationDuration		0.30

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Configuration", @"Default title of ConfigViewController");
	}
	return self;
}

- (void)dealloc
{
	[myTableView release];
	[remoteAddressTextField release];
	[usernameTextField release];
	[passwordTextField release];

	[super dealloc];
}

- (UITextField *)create_TextField
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, kTextFieldHeight);
	UITextField *returnTextField = [[UITextField alloc] initWithFrame:frame];

	returnTextField.leftView = nil;
	returnTextField.leftViewMode = UITextFieldViewModeNever;
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [UIFont systemFontOfSize:17.0];
    returnTextField.backgroundColor = [UIColor whiteColor];
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support

	returnTextField.keyboardType = UIKeyboardTypeDefault;
	returnTextField.returnKeyType = UIReturnKeyDone;

	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right

	return returnTextField;
}

- (void)loadView
{
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	// XXX: We might want to add a custom left button to cancel when editing, just leaving the view might not be obvious

	// create and configure the table view
	myTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	myTableView.delegate = self;
	myTableView.dataSource = self;

	// setup our content view so that it auto-rotates along with the UViewController
	myTableView.autoresizesSubviews = YES;
	myTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = myTableView;

	// Remote Address
	remoteAddressTextField = [[self create_TextField] retain];
	remoteAddressTextField.placeholder = NSLocalizedString(@"<remote address>", @"");
	remoteAddressTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey: kRemoteHost];
	remoteAddressTextField.keyboardType = UIKeyboardTypeURL;

	// Username
	usernameTextField = [[self create_TextField] retain];
	usernameTextField.placeholder = NSLocalizedString(@"<remote username>", @"");
	usernameTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey: kUsername];

	// Password
	passwordTextField = [[self create_TextField] retain];
	passwordTextField.placeholder = NSLocalizedString(@"<remote password>", @"");
	passwordTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey: kPassword];
	passwordTextField.secureTextEntry = YES;

	// Connector
	_connector = [[[NSUserDefaults standardUserDefaults] stringForKey: kConnector] integerValue];
	
	// RC Vibration
	vibrateInRC = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[vibrateInRC setOn: [[NSUserDefaults standardUserDefaults] boolForKey: kVibratingRC]];
	
	// in case the parent view draws with a custom color or gradient, use a transparent color
	vibrateInRC.backgroundColor = [UIColor clearColor];
	vibrateInRC.enabled = NO;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
	[super setEditing: editing animated: animated];

	vibrateInRC.enabled = editing;
	if(!editing)
	{
		[remoteAddressCell stopEditing];
		[usernameCell stopEditing];
		[passwordCell stopEditing];

		if(_shouldSave)
		{
			[[NSUserDefaults standardUserDefaults] setObject: remoteAddressTextField.text forKey: kRemoteHost];
			[[NSUserDefaults standardUserDefaults] setObject: usernameTextField.text forKey: kUsername];
			[[NSUserDefaults standardUserDefaults] setObject: passwordTextField.text forKey: kPassword];
			[[NSUserDefaults standardUserDefaults] setInteger: _connector forKey: kConnector];
			[[NSUserDefaults standardUserDefaults] setBool: vibrateInRC.on forKey: kVibratingRC];

			[RemoteConnectorObject createConnector: remoteAddressTextField.text : usernameTextField.text : passwordTextField.text : _connector];
		}
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)connectorSelected: (NSNumber*) newConnector
{
	if(newConnector == nil)
		return;

	_connector = [newConnector intValue];

	if(_connector == kEnigma1Connector)
		connectorCell.text = NSLocalizedString(@"Enigma", "");
	else
		connectorCell.text = NSLocalizedString(@"Enigma 2", "");
}

#pragma mark - UITableView delegates

// if you want the entire table to just be re-orderable then just return UITableViewCellEditingStyleNone
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:
			return NSLocalizedString(@"Remote Host", @"");
		case 1:
			return NSLocalizedString(@"Credential", @"");
		case 2:
			return NSLocalizedString(@"Remote Box Type", @"");
		case 3:
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 1)
		return 2;
	return 1;
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kUIRowHeight;
}

// utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell to be used on a given section.
//
- (UITableViewCell *)obtainTableCellForSection:(NSInteger)section
{
	static NSString *kVanilla_ID = @"Vanilla_ID";

	UITableViewCell *cell = nil;

	switch(section)
	{
		case 0:
		case 1:
			cell = [myTableView dequeueReusableCellWithIdentifier: kCellTextField_ID];
			if(cell == nil)
				cell = [[[CellTextField alloc] initWithFrame: CGRectZero reuseIdentifier: kCellTextField_ID] autorelease];
			((CellTextField *)cell).delegate = self;	// so we can detect when cell editing starts
			break;
		case 2:
			cell = [myTableView dequeueReusableCellWithIdentifier: kVanilla_ID];
			if (cell == nil) 
				cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
			break;
		case 3:
			cell = [myTableView dequeueReusableCellWithIdentifier: kDisplayCell_ID];
			if(cell == nil)
				cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
			break;
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
	UITableViewCell *sourceCell = [self obtainTableCellForSection: section];

	// we are creating a new cell, setup its attributes
	switch(section)
	{
		case 0:
			((CellTextField *)sourceCell).view = remoteAddressTextField;
			remoteAddressCell = (CellTextField *)sourceCell;
			break;
		case 1:
			switch(indexPath.row)
			{
				case 0:
					((CellTextField *)sourceCell).view = usernameTextField;
					usernameCell = (CellTextField *)sourceCell;
					break;
				case 1:
					((CellTextField *)sourceCell).view = passwordTextField;
					passwordCell = (CellTextField *)sourceCell;
					break;
				default:
					break;
			}
			break;
		case 2:
			if(_connector == kEnigma1Connector)
				((UITableViewCell *)sourceCell).text = NSLocalizedString(@"Enigma", "");
			else
				((UITableViewCell *)sourceCell).text = NSLocalizedString(@"Enigma 2", "");

			connectorCell = (UITableViewCell *)sourceCell;
			break;
		case 3:
			((DisplayCell *)sourceCell).view = vibrateInRC;
			((DisplayCell *)sourceCell).text = NSLocalizedString(@"Vibrate in RC", @"");
			break;
		default:
			break;
	}

	return sourceCell;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(self.editing && indexPath.section == 2)
	{
		_shouldSave = NO;

		id applicationDelegate = [[UIApplication sharedApplication] delegate];

		ConnectorViewController *connectorViewController = [ConnectorViewController withConnector: _connector];
		[connectorViewController setTarget: self action: @selector(connectorSelected:)];
		[[applicationDelegate navigationController] pushViewController: connectorViewController animated: YES];
	}
	
	// We don't want any actual response :-)
    return nil;
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tv accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    // Show the disclosure indicator in section 2 if editing.
    return (self.editing && indexPath.section == 2) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management

- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{

    // notify other cells to end editing
    if (![cell isEqual: remoteAddressCell])
		[remoteAddressCell stopEditing];
	if (![cell isEqual: usernameCell])
		[usernameCell stopEditing];
	if (![cell isEqual: passwordCell])
		[passwordCell stopEditing];

    return self.editing;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	if ([cell isEqual: usernameCell] || [cell isEqual: passwordCell])
	{
        // Restore the position of the main view if it was animated to make room for the keyboard.
        if  (self.view.frame.origin.y < 0)
		{
            [self setViewMovedUp:NO];
        }
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
    // The keyboard will be shown. If the user is editing the author, adjust the display so that the
    // author field will not be covered by the keyboard.
    if ((usernameCell.isInlineEditing || passwordCell.isInlineEditing) && self.view.frame.origin.y >= 0)
	{
        [self setViewMovedUp:YES];
    }
	else if (!passwordCell.isInlineEditing && self.view.frame.origin.y < 0)
	{
        [self setViewMovedUp:NO];
    }
}

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
    // watch the keyboard so we can adjust the user interface if necessary.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
												 name:UIKeyboardWillShowNotification object:self.view.window];
	
	_shouldSave = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
}

@end
