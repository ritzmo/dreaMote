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

#import "DisplayCell.h"

@interface ConfigViewController()
- (void)setViewMovedUp:(BOOL)movedUp;
@end

@implementation ConfigViewController

@synthesize connection;
@synthesize connectionIndex;
@synthesize makeDefaultButton;
@synthesize connectButton;

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

+ (ConfigViewController *)withConnection: (NSMutableDictionary *)newConnection: (NSInteger)atIndex;
{
	ConfigViewController *configViewController = [[ConfigViewController alloc] init];
	configViewController.connection = newConnection;
	configViewController.connectionIndex = atIndex;

	return configViewController;
}

+ (ConfigViewController *)newConnection
{
	ConfigViewController *configViewController = [[ConfigViewController alloc] init];
	configViewController.connection = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																			@"dreambox", kRemoteHost,
																			@"", kUsername,
																			@"", kPassword,
																			[NSNumber numberWithInteger: kEnigma2Connector], kConnector,
																			nil];
	configViewController.connectionIndex = -1;

	return configViewController;
}

- (void)dealloc
{
	[remoteAddressTextField release];
	[usernameTextField release];
	[passwordTextField release];
	[makeDefaultButton release];
	[connectButton release];

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

- (UIButton *)create_DefaultButton
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect]; // XXX: an icon would be nice ;)
	button.frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	[button addTarget:self action:@selector(makeDefault:) forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}

- (UIButton *)create_ConnectButton
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect]; // XXX: an icon would be nice ;)
	button.frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	[button addTarget:self action:@selector(doConnect:) forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}

- (void)loadView
{
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	tableView.delegate = self;
	tableView.dataSource = self;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];

	// Remote Address
	remoteAddressTextField = [[self create_TextField] retain];
	remoteAddressTextField.placeholder = NSLocalizedString(@"<remote address>", @"");
	remoteAddressTextField.text = [[connection objectForKey: kRemoteHost] copy];
	remoteAddressTextField.keyboardType = UIKeyboardTypeURL;

	// Username
	usernameTextField = [[self create_TextField] retain];
	usernameTextField.placeholder = NSLocalizedString(@"<remote username>", @"");
	usernameTextField.text = [[connection objectForKey: kUsername] copy];

	// Password
	passwordTextField = [[self create_TextField] retain];
	passwordTextField.placeholder = NSLocalizedString(@"<remote password>", @"");
	passwordTextField.text = [[connection objectForKey: kPassword] copy];
	passwordTextField.secureTextEntry = YES;

	// Connector
	_connector = [[connection objectForKey: kConnector] integerValue];

	// Connect Button
	self.connectButton = [self create_ConnectButton];
	connectButton.enabled = NO;
	
	// "Make Default" Button
	self.makeDefaultButton = [self create_DefaultButton];
	makeDefaultButton.enabled = NO;

	[self setEditing: YES animated: NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
	[super setEditing: editing animated: animated];

	makeDefaultButton.enabled = editing;
	connectButton.enabled = editing;

	if(!editing)
	{
		[self.navigationItem setLeftBarButtonItem: nil animated: YES];

		[remoteAddressCell stopEditing];
		[usernameCell stopEditing];
		[passwordCell stopEditing];

		if(_shouldSave)
		{
			[connection setObject: remoteAddressTextField.text forKey: kRemoteHost];
			[connection setObject: usernameTextField.text forKey: kUsername];
			[connection setObject: passwordTextField.text forKey: kPassword];
			[connection setObject: [NSNumber numberWithInteger: _connector] forKey: kConnector];

			NSMutableArray *connections = [RemoteConnectorObject getConnections];
			if(connectionIndex == -1)
				[connections addObject: connection];
			else
				[connections replaceObjectAtIndex: connectionIndex withObject: connection];
		}
	}
	else
	{
		_shouldSave = YES;
		[self.navigationItem setLeftBarButtonItem: [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(cancelEdit:)] animated: YES]; 
	}
}

- (void)cancelEdit: (id)sender
{
	_shouldSave = NO;
	[self setEditing: NO animated: YES];
}

- (void)makeDefault: (id)sender
{
	[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithInteger: connectionIndex] forKey: kActiveConnection];
	[RemoteConnectorObject connectTo: connectionIndex];
}

- (void)doConnect: (id)sender
{
	[RemoteConnectorObject connectTo: connectionIndex];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)connectorSelected: (NSNumber*) newConnector
{
	if(newConnector == nil)
		return;

	_connector = [newConnector integerValue];

	if(_connector == kEnigma1Connector)
		connectorCell.text = NSLocalizedString(@"Enigma", @"");
	else
		connectorCell.text = NSLocalizedString(@"Enigma 2", @"");
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
	if(connectionIndex == -1 || connectionIndex == [[[NSUserDefaults standardUserDefaults] objectForKey: kActiveConnection] integerValue])
		return 3;
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
	if(section == 1 || section == 3)
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
- (UITableViewCell *)obtainTableCellForSection:(UITableView *)tableView: (NSInteger)section
{
	static NSString *kVanilla_ID = @"Vanilla_ID";

	UITableViewCell *cell = nil;

	switch(section)
	{
		case 0:
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier: kCellTextField_ID];
			if(cell == nil)
				cell = [[[CellTextField alloc] initWithFrame: CGRectZero reuseIdentifier: kCellTextField_ID] autorelease];
			((CellTextField *)cell).delegate = self;	// so we can detect when cell editing starts
			break;
		case 2:
			cell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
			if (cell == nil) 
				cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
			break;
		case 3:
			cell = [tableView dequeueReusableCellWithIdentifier: kDisplayCell_ID];
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
	UITableViewCell *sourceCell = [self obtainTableCellForSection: tableView: section];

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
				sourceCell.text = NSLocalizedString(@"Enigma", @"");
			else
				sourceCell.text = NSLocalizedString(@"Enigma 2", @"");

			connectorCell = sourceCell;
			break;
		case 3:
			switch(indexPath.row)
			{
				case 0:
					((DisplayCell *)sourceCell).view = connectButton;
					((DisplayCell *)sourceCell).text = NSLocalizedString(@"Connect", @"");
					break;
				case 1:
					((DisplayCell *)sourceCell).view = makeDefaultButton;
					((DisplayCell *)sourceCell).text = NSLocalizedString(@"Make Default", @"");
					break;
				default:
					break;
			}
			break;
		default:
			break;
	}

	return sourceCell;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(self.editing && indexPath.section == 2)
	{
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
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
}

@end
