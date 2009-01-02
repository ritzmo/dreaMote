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
#define kOFFSET_FOR_KEYBOARD					110.0

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
																[NSNumber numberWithInteger:
																	kEnigma2Connector], kConnector,
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
	[_singleBouquetSwitch release];

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

- (UIButton *)create_DefaultButton
{
	CGRect frame = CGRectMake(0.0, 0.0, kUIRowHeight, kUIRowHeight);
	UIButton *button = [[UIButton alloc] initWithFrame: frame];
	UIImage *image = [UIImage imageNamed:@"emblem-favorite.png"];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(makeDefault:)
				forControlEvents:UIControlEventTouchUpInside];

	return [button autorelease];
}

- (UIButton *)create_ConnectButton
{
	CGRect frame = CGRectMake(0.0, 0.0, kUIRowHeight, kUIRowHeight);
	UIButton *button = [[UIButton alloc] initWithFrame: frame];
	UIImage *image = [UIImage imageNamed:@"network-wired.png"];
	[button setImage:image forState:UIControlStateNormal];
	[button addTarget:self action:@selector(doConnect:)
				forControlEvents:UIControlEventTouchUpInside];

	return [button autorelease];
}

- (void)loadView
{
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = kUIRowHeight;

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
	connectButton.enabled = YES;
	
	// "Make Default" Button
	self.makeDefaultButton = [self create_DefaultButton];
	makeDefaultButton.enabled = YES;

	// Single bouquet switch
	_singleBouquetSwitch = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, kSwitchButtonWidth, kSwitchButtonHeight)];
	_singleBouquetSwitch.on = [[connection objectForKey: kSingleBouquet] boolValue];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_singleBouquetSwitch.backgroundColor = [UIColor clearColor];

	[self setEditing: (connectionIndex == -1) animated: NO];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
	[super setEditing: editing animated: animated];

	/*makeDefaultButton.enabled = editing;
	connectButton.enabled = editing;*/

	if(!editing)
	{
		[self.navigationItem setLeftBarButtonItem: nil animated: YES];

		[remoteAddressCell stopEditing];
		[usernameCell stopEditing];
		[passwordCell stopEditing];
		_singleBouquetSwitch.enabled = NO;

		if(_shouldSave)
		{
			[connection setObject: remoteAddressTextField.text forKey: kRemoteHost];
			[connection setObject: usernameTextField.text forKey: kUsername];
			[connection setObject: passwordTextField.text forKey: kPassword];
			[connection setObject: [NSNumber numberWithInteger: _connector] forKey: kConnector];
			[connection setObject: _singleBouquetSwitch.on ? @"YES" : @"NO" forKey: kSingleBouquet];

			NSMutableArray *connections = [RemoteConnectorObject getConnections];
			if(connectionIndex == -1)
			{
				[(UITableView *)self.view beginUpdates];
				connectionIndex = [connections count];
				[connections addObject: connection];
				// XXX: ugly!
				if(connectionIndex != [[NSUserDefaults standardUserDefaults] integerForKey: kActiveConnection] || connectionIndex != [RemoteConnectorObject getConnectedId])
					[(UITableView *)self.view insertSections: [NSIndexSet indexSetWithIndex: 3]
											withRowAnimation: UITableViewRowAnimationFade];
				[(UITableView *)self.view endUpdates];
			}
			else
			{
				[connections replaceObjectAtIndex: connectionIndex withObject: connection];

				// Reconnect because changes won't be applied otherwise
				if(connectionIndex == [RemoteConnectorObject getConnectedId])
					[RemoteConnectorObject connectTo: connectionIndex];
			}
		}

		connectorCell.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		_shouldSave = YES;
		_singleBouquetSwitch.enabled = YES;
		UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(cancelEdit:)];
		[self.navigationItem setLeftBarButtonItem: cancelButtonItem animated: YES];
		[cancelButtonItem release];
		connectorCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
}

- (void)cancelEdit: (id)sender
{
	_shouldSave = NO;
	[self setEditing: NO animated: YES];
	[self.navigationController popViewControllerAnimated: YES];
}

- (void)makeDefault: (id)sender
{
	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber *activeConnection = [NSNumber numberWithInteger: connectionIndex];
	[stdDefaults setObject: activeConnection forKey: kActiveConnection];
	[RemoteConnectorObject connectTo: connectionIndex];

	[(UITableView *)self.view deleteSections: [NSIndexSet indexSetWithIndex: 3]
								withRowAnimation: UITableViewRowAnimationFade];
}

- (void)doConnect: (id)sender
{
	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];

	[RemoteConnectorObject connectTo: connectionIndex];

	if(connectionIndex == [stdDefaults integerForKey: kActiveConnection])
		[(UITableView *)self.view deleteSections: [NSIndexSet indexSetWithIndex: 3]
									withRowAnimation: UITableViewRowAnimationFade];
	else
		[(UITableView *)self.view
				deleteRowsAtIndexPaths: [NSArray arrayWithObject:
											[NSIndexPath indexPathForRow:0 inSection:3]]
				withRowAnimation: UITableViewRowAnimationFade];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)connectorSelected: (NSNumber*) newConnector
{
	if(newConnector == nil)
		return;

	NSInteger oldConnector = _connector;
	_connector = [newConnector integerValue];

	if(_connector == kInvalidConnector)
	{
		((UITableView *)self.view).userInteractionEnabled = NO;

		NSDictionary *tempConnection = [NSDictionary dictionaryWithObjectsAndKeys:
								remoteAddressTextField.text, kRemoteHost,
								usernameTextField.text, kUsername,
								passwordTextField.text, kPassword,
								nil];

		_connector = [RemoteConnectorObject autodetectConnector: tempConnection];
		if(_connector == kInvalidConnector)
		{
			UIAlertView *notification = [[UIAlertView alloc]
								initWithTitle:NSLocalizedString(@"Error", @"")
								message:NSLocalizedString(@"Could not determine remote box type.", @"")
								delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[notification show];
			[notification release];

			_connector = oldConnector;
		}

		((UITableView *)self.view).userInteractionEnabled = YES;
	}

	if(_connector == kEnigma1Connector)
		connectorCell.text = NSLocalizedString(@"Enigma", @"");
	else if(_connector == kEnigma2Connector)
		connectorCell.text = NSLocalizedString(@"Enigma 2", @"");
	else if(_connector == kNeutrinoConnector)
		connectorCell.text = NSLocalizedString(@"Neutrino", @"");
	else
		connectorCell.text = @"???";
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
	if(	connectionIndex == -1
		|| (connectionIndex == [[NSUserDefaults standardUserDefaults] integerForKey: kActiveConnection] && connectionIndex == [RemoteConnectorObject getConnectedId]))
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
	if(section == 1)
		return 2;
	// XXX: HAAAAAAACK - but I really wanted this feature :P
	if(section == 2 && _connector == kEnigma2Connector)
		return 2;
	if(section == 3)
	{
		NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
		if(connectionIndex == [stdDefaults integerForKey: kActiveConnection]
			|| connectionIndex == [RemoteConnectorObject getConnectedId])
			return 1;
		return 2;
	}
	return 1;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kVanilla_ID = @"Vanilla_ID";

	NSInteger section = indexPath.section;
	NSInteger row;
	UITableViewCell *sourceCell = nil;

	// we are creating a new cell, setup its attributes
	switch(section)
	{
		case 0:
			sourceCell = [tableView dequeueReusableCellWithIdentifier: kCellTextField_ID];
			if(sourceCell == nil)
				sourceCell = [[[CellTextField alloc] initWithFrame: CGRectZero reuseIdentifier: kCellTextField_ID] autorelease];
			((CellTextField *)sourceCell).delegate = self; // so we can detect when cell editing starts

			((CellTextField *)sourceCell).view = remoteAddressTextField;
			remoteAddressCell = (CellTextField *)sourceCell;
			break;
		case 1:
			sourceCell = [tableView dequeueReusableCellWithIdentifier: kCellTextField_ID];
			if(sourceCell == nil)
				sourceCell = [[[CellTextField alloc] initWithFrame: CGRectZero reuseIdentifier: kCellTextField_ID] autorelease];
			((CellTextField *)sourceCell).delegate = self; // so we can detect when cell editing starts

			row = indexPath.row;
			
			switch(row)
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
			row = indexPath.row;
			switch(row)
			{
				case 0:
					sourceCell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
					if (sourceCell == nil) 
						sourceCell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
					
					if(self.editing)
						sourceCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					
					if(_connector == kEnigma1Connector)
						sourceCell.text = NSLocalizedString(@"Enigma", @"");
					else if(_connector == kEnigma2Connector)
						sourceCell.text = NSLocalizedString(@"Enigma 2", @"");
					else if(_connector == kNeutrinoConnector)
						sourceCell.text = NSLocalizedString(@"Neutrino", @"");
					else
						sourceCell.text = @"???";
					
					connectorCell = sourceCell;
					break;
				case 1:
					sourceCell = [tableView dequeueReusableCellWithIdentifier: kDisplayCell_ID];
					if(sourceCell == nil)
						sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Single Bouquet", @"");
					((DisplayCell *)sourceCell).view = _singleBouquetSwitch;
					break;
			}
			break;
		case 3:
			sourceCell = [tableView dequeueReusableCellWithIdentifier: kDisplayCell_ID];
			if(sourceCell == nil)
				sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

			row = indexPath.row;

			if(connectionIndex == [RemoteConnectorObject getConnectedId])
				row++;

			switch(row)
			{
				case 0:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Connect", @"");
					((DisplayCell *)sourceCell).view = connectButton;
					break;
				case 1:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Make Default", @"");
					((DisplayCell *)sourceCell).view = makeDefaultButton;
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
	if(self.editing && indexPath.section == 2 && indexPath.row == 0)
	{
		ConnectorViewController *targetViewController = [ConnectorViewController withConnector: _connector];
		[targetViewController setTarget: self action: @selector(connectorSelected:)];
		[self.navigationController pushViewController: targetViewController animated: YES];
		[targetViewController release];
	}

	// We don't want any actual response :-)
    return nil;
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management

- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	// notify other cells to end editing
	if([cell isEqual: remoteAddressCell])
	{
		[usernameCell stopEditing];
		[passwordCell stopEditing];
	}
	else
		[remoteAddressCell stopEditing];

	// XXX: usernameCell & passwordCell will track this themselves

	return self.editing;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	if(([cell isEqual: usernameCell] && ! passwordCell.isInlineEditing)
		|| ([cell isEqual: passwordCell] && !usernameCell.isInlineEditing))
	{
        // Restore the position of the main view if it was animated to make room for the keyboard.
        if  (self.view.frame.origin.y < 0)
		{
            [self setViewMovedUp:NO];
        }
    }
}

// Animate the entire view up or down, to prevent the keyboard from covering the text field.
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
	// The keyboard will be shown. If the user is editing the username or password, adjust the
	// display so that the field will not be covered by the keyboard.
	if(usernameCell.isInlineEditing || passwordCell.isInlineEditing)
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
												name:UIKeyboardWillShowNotification
												object:self.view.window];

	[super viewWillAppear: animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
												name:UIKeyboardWillShowNotification
												object:nil]; 

	[super viewWillDisappear: animated];
}

@end
