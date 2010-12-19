//
//  ConfigViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "ConfigViewController.h"

#import "RemoteConnector.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "DisplayCell.h"

/*!
 @brief Private functions of ConfigViewController.
 */
@interface ConfigViewController()
/*!
 @brief Animate View up or down.
 Animate the entire view up or down, to prevent the keyboard from covering the text field.
 
 @param movedUp YES if moving down again.
 */
- (void)setViewMovedUp:(BOOL)movedUp;

/*!
 @brief Create standardized UITextField.
 
 @return UITextField instance.
 */
- (UITextField *)create_TextField;

/*!
 @brief Create standardized UIButton.
 
 @param imageName Name of Image to illustrate button with.
 @param action Selector to call on UIControlEventTouchUpInside.
 @return UIButton instance.
 */
- (UIButton *)create_Button: (NSString *)imageName: (SEL)action;

/*!
 @brief Selector to call when _makeDefaultButton was pressed.
 
 @param sender Unused instance of sender.
 */
- (void)makeDefault: (id)sender;

/*!
 @brief Selector to call when _connectButton was pressed.
 
 @param sender Unused instance of sender.
 */
- (void)doConnect: (id)sender;

/*!
 @brief stop editing
 @param sender ui element
 */
- (void)cancelEdit: (id)sender;
@end


@implementation ConfigViewController

@synthesize connection = _connection;
@synthesize connectionIndex = _connectionIndex;
@synthesize makeDefaultButton = _makeDefaultButton;
@synthesize connectButton = _connectButton;

/*!
 @brief Keyboard offset.
 The amount of vertical shift upwards to keep the text field in view as the keyboard appears.
 */
#define kOFFSET_FOR_KEYBOARD					150

/*! @brief The duration of the animation for the view shift. */
#define kVerticalOffsetAnimationDuration		(CGFloat)0.30

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Configuration", @"Default title of ConfigViewController");
		_connectorCell = nil;
	}
	return self;
}

/* initiate ConfigViewController with given connection and index */
+ (ConfigViewController *)withConnection: (NSMutableDictionary *)newConnection: (NSInteger)atIndex
{
	ConfigViewController *configViewController = [[ConfigViewController alloc] init];
	configViewController.connection = newConnection;
	configViewController.connectionIndex = atIndex;

	return [configViewController autorelease];
}

/* initiate ConfigViewController with new connection */
+ (ConfigViewController *)newConnection
{
	ConfigViewController *configViewController = [[ConfigViewController alloc] init];
	configViewController.connection = [NSMutableDictionary dictionaryWithObjectsAndKeys:
																@"", kRemoteHost,
																@"", kRemoteName,
																@"", kUsername,
																@"", kPassword,
																[NSNumber numberWithInteger:
																	kEnigma2Connector], kConnector,
																nil];
	configViewController.connectionIndex = -1;

	return configViewController;
}

/* dealloc */
- (void)dealloc
{
	[_remoteNameTextField release];
	[_remoteAddressTextField release];
	[_remotePortTextField release];
	[_usernameTextField release];
	[_passwordTextField release];
	[_makeDefaultButton release];
	[_connectButton release];
	[_singleBouquetSwitch release];
	[_advancedRemoteSwitch release];

	[super dealloc];
}

/* create a textfield */
- (UITextField *)create_TextField
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
	returnTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
	returnTextField.keyboardType = UIKeyboardTypeDefault;
	returnTextField.returnKeyType = UIReturnKeyDone;

	// has a clear 'x' button to the right
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

	return [returnTextField autorelease];
}

/* create a button */
- (UIButton *)create_Button: (NSString *)imageName: (SEL)action
{
	const CGRect frame = CGRectMake(0, 0, kUIRowHeight, kUIRowHeight);
	UIButton *button = [[UIButton alloc] initWithFrame: frame];
	UIImage *image = [UIImage imageNamed: imageName];
	[button setImage: image forState: UIControlStateNormal];
	[button addTarget: self action: action
		forControlEvents: UIControlEventTouchUpInside];
	
	return [button autorelease];
}

/* layout */
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

	// Remote Name
	NSString *remoteName = [_connection objectForKey: kRemoteName];
	if(remoteName == nil) // Work around unset property
		remoteName = @"";
	_remoteNameTextField = [[self create_TextField] retain];
	_remoteNameTextField.placeholder = NSLocalizedString(@"<name>", @"");
	_remoteNameTextField.text = [remoteName copy];

	// Remote Address
	_remoteAddressTextField = [[self create_TextField] retain];
	_remoteAddressTextField.placeholder = NSLocalizedString(@"<remote address>", @"");
	_remoteAddressTextField.text = [[_connection objectForKey: kRemoteHost] copy];
	_remoteAddressTextField.keyboardType = UIKeyboardTypeURL;

	// Remote Port
	const NSNumber *port = [_connection objectForKey: kPort];
	_remotePortTextField = [[self create_TextField] retain];
	_remotePortTextField.placeholder = NSLocalizedString(@"<remote port>", @"");
	_remotePortTextField.text = [port integerValue] ? [port stringValue] : nil;
	_remotePortTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation; // NOTE: we lack a better one :-)

	// SSL
	_sslSwitch = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, kSwitchButtonWidth, kSwitchButtonHeight)];
	_sslSwitch.on = [[_connection objectForKey: kSSL] boolValue];

	// Username
	_usernameTextField = [[self create_TextField] retain];
	_usernameTextField.placeholder = NSLocalizedString(@"<remote username>", @"");
	_usernameTextField.text = [[_connection objectForKey: kUsername] copy];

	// Password
	_passwordTextField = [[self create_TextField] retain];
	_passwordTextField.placeholder = NSLocalizedString(@"<remote password>", @"");
	_passwordTextField.text = [[_connection objectForKey: kPassword] copy];
	_passwordTextField.secureTextEntry = YES;

	// Connector
	_connector = [[_connection objectForKey: kConnector] integerValue];

	// Connect Button
	self.connectButton = [self create_Button: @"network-wired.png": @selector(doConnect:)];
	_connectButton.enabled = YES;
	
	// "Make Default" Button
	self.makeDefaultButton = [self create_Button: @"emblem-favorite.png": @selector(makeDefault:)];
	_makeDefaultButton.enabled = YES;

	// Single bouquet switch
	_singleBouquetSwitch = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, kSwitchButtonWidth, kSwitchButtonHeight)];
	_singleBouquetSwitch.on = [[_connection objectForKey: kSingleBouquet] boolValue];
	
	// Advanced Remote switch
	_advancedRemoteSwitch = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, kSwitchButtonWidth, kSwitchButtonHeight)];
	_advancedRemoteSwitch.on = [[_connection objectForKey: kAdvancedRemote] boolValue];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_singleBouquetSwitch.backgroundColor = [UIColor clearColor];
	_advancedRemoteSwitch.backgroundColor = [UIColor clearColor];

	[self setEditing: (_connectionIndex == -1) animated: NO];
}

/* (un)set editing */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];

	/*_makeDefaultButton.enabled = editing;
	_connectButton.enabled = editing;*/

	if(!editing)
	{
		[self.navigationItem setLeftBarButtonItem: nil animated: YES];

		[_remoteNameCell stopEditing];
		[_remoteAddressCell stopEditing];
		[_remotePortCell stopEditing];
		[_usernameCell stopEditing];
		[_passwordCell stopEditing];
		_singleBouquetSwitch.enabled = NO;
		_advancedRemoteSwitch.enabled = NO;
		_sslSwitch.enabled = NO;

		if(_shouldSave)
		{
			[_connection setObject: _remoteNameTextField.text forKey: kRemoteName];
			[_connection setObject: _remoteAddressTextField.text forKey: kRemoteHost];
			[_connection setObject: [NSNumber numberWithInteger: [_remotePortTextField.text integerValue]] forKey: kPort];
			[_connection setObject: _usernameTextField.text forKey: kUsername];
			[_connection setObject: _passwordTextField.text forKey: kPassword];
			[_connection setObject: [NSNumber numberWithInteger: _connector] forKey: kConnector];
			[_connection setObject: _singleBouquetSwitch.on ? @"YES" : @"NO" forKey: kSingleBouquet];
			[_connection setObject: _advancedRemoteSwitch.on ? @"YES" : @"NO" forKey: kAdvancedRemote];
			[_connection setObject: _sslSwitch.on ? @"YES" : @"NO" forKey: kSSL];

			NSMutableArray *connections = [RemoteConnectorObject getConnections];
			if(_connectionIndex == -1)
			{
				[(UITableView *)self.view beginUpdates];
				_connectionIndex = [connections count];
				[connections addObject: _connection];
				// FIXME: ugly!
				if(_connectionIndex != [[NSUserDefaults standardUserDefaults] integerForKey: kActiveConnection] || _connectionIndex != [RemoteConnectorObject getConnectedId])
					[(UITableView *)self.view insertSections: [NSIndexSet indexSetWithIndex: 3]
											withRowAnimation: UITableViewRowAnimationFade];
				[(UITableView *)self.view endUpdates];
			}
			else
			{
				[connections replaceObjectAtIndex: _connectionIndex withObject: _connection];

				// Reconnect because changes won't be applied otherwise
				if(_connectionIndex == [RemoteConnectorObject getConnectedId])
					[RemoteConnectorObject connectTo: _connectionIndex];
			}
		}

		if(_connectorCell)
			_connectorCell.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		_shouldSave = YES;
		_singleBouquetSwitch.enabled = YES;
		_advancedRemoteSwitch.enabled = YES;
		_sslSwitch.enabled = YES;
		UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(cancelEdit:)];
		[self.navigationItem setLeftBarButtonItem: cancelButtonItem animated: YES];
		[cancelButtonItem release];

		if(_connectorCell)
			_connectorCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
}

/* cancel and close */
- (void)cancelEdit: (id)sender
{
	_shouldSave = NO;
	[self setEditing: NO animated: YES];
	[self.navigationController popViewControllerAnimated: YES];
}

/* "make default" button pressed */
- (void)makeDefault: (id)sender
{
	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber *activeConnection = [NSNumber numberWithInteger: _connectionIndex];

	if(![RemoteConnectorObject connectTo: _connectionIndex])
	{
		// error connecting... what now?
		UIAlertView *notification = [[UIAlertView alloc]
									 initWithTitle:NSLocalizedString(@"Error", @"")
									 message:NSLocalizedString(@"Unable to connect to host.\nPlease restart the application.", @"")
									 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
		[notification release];
		return;
	}
	[stdDefaults setObject: activeConnection forKey: kActiveConnection];

	[(UITableView *)self.view beginUpdates];
	[(UITableView *)self.view deleteSections: [NSIndexSet indexSetWithIndex: 3]
								withRowAnimation: UITableViewRowAnimationFade];
	[(UITableView *)self.view endUpdates];
}

/* "connect" button pressed */
- (void)doConnect: (id)sender
{
	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];

	if(![RemoteConnectorObject connectTo: _connectionIndex])
	{
		// error connecting... what now?
		UIAlertView *notification = [[UIAlertView alloc]
									 initWithTitle:NSLocalizedString(@"Error", @"")
									 message:NSLocalizedString(@"Unable to connect to host.\nPlease restart the application.", @"")
									 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
		[notification release];
		return;
	}

	[(UITableView *)self.view beginUpdates];
	if(_connectionIndex == [stdDefaults integerForKey: kActiveConnection])
		[(UITableView *)self.view deleteSections: [NSIndexSet indexSetWithIndex: 3]
									withRowAnimation: UITableViewRowAnimationFade];
	else
		[(UITableView *)self.view
				deleteRowsAtIndexPaths: [NSArray arrayWithObject:
											[NSIndexPath indexPathForRow:0 inSection:3]]
				withRowAnimation: UITableViewRowAnimationFade];
	[(UITableView *)self.view endUpdates];
}

/* rotate to portrait mode */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - <ConnectorDelegate> methods

/* connector selected */
- (void)connectorSelected: (NSNumber*) newConnector
{
	if(newConnector == nil)
		return;

	const NSInteger oldConnector = _connector;
	_connector = [newConnector integerValue];

	if(_connector == kInvalidConnector)
	{
		((UITableView *)self.view).userInteractionEnabled = NO;

		NSDictionary *tempConnection = [NSDictionary dictionaryWithObjectsAndKeys:
								_remoteAddressTextField.text, kRemoteHost,
								//_remotePortTextField.text, kPort,
								_usernameTextField.text, kUsername,
								_passwordTextField.text, kPassword,
								_sslSwitch.on ? @"YES" : @"NO", kSSL,
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
		TABLEVIEWCELL_TEXT(_connectorCell) = NSLocalizedString(@"Enigma", @"");
	else if(_connector == kEnigma2Connector)
		TABLEVIEWCELL_TEXT(_connectorCell) = NSLocalizedString(@"Enigma 2", @"");
	else if(_connector == kNeutrinoConnector)
		TABLEVIEWCELL_TEXT(_connectorCell) = NSLocalizedString(@"Neutrino", @"");
	else if(_connector == kSVDRPConnector)
		TABLEVIEWCELL_TEXT(_connectorCell) = NSLocalizedString(@"SVDRP", @"");
	else
		TABLEVIEWCELL_TEXT(_connectorCell) = @"???";

	[(UITableView *)self.view reloadData];
}

#pragma mark - UITableView delegates

/* no editing style for any cell */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if(	_connectionIndex == -1
		|| (_connectionIndex == [[NSUserDefaults standardUserDefaults] integerForKey: kActiveConnection] && _connectionIndex == [RemoteConnectorObject getConnectedId]))
		return 3;
	return 4;
}

/* title for sections */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:
			return NSLocalizedString(@"Remote Host", @"");
		case 1:
			if(_connector == kSVDRPConnector)
				return nil;
			return NSLocalizedString(@"Credential", @"");
		case 2:
			return NSLocalizedString(@"Remote Box Type", @"");
		case 3:
		default:
			return nil;
	}
}

/* rows per section */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:
			if(_connector == kSVDRPConnector)
				return 3;
			return 4;
		case 1:
			if(_connector == kSVDRPConnector)
				return 0;
			return 2;
		case 2:
			/*!
			 @brief Add "single bouquet" & "advanced remote" switch for Enigma2 based STBs.
			 @note Actually this is an ugly hack but I really wanted this feature :P
			 */
			if(_connector == kEnigma2Connector)
				return 3;
			return 1;
		case 3:
			if(_connectionIndex == [[NSUserDefaults standardUserDefaults] integerForKey: kActiveConnection]
			   || _connectionIndex == [RemoteConnectorObject getConnectedId])
				return 1;
			return 2;
	}
	return 0;
}

// to determine specific row height for each cell, override this. 
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case 1:
			if(_connector == kSVDRPConnector)
				return 0;
		default:
			return kUIRowHeight;
	}
}

/* determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	UITableViewCell *sourceCell = nil;

	// we are creating a new cell, setup its attributes
	switch(section)
	{
		case 0:
			if(row == 3)
			{
				sourceCell = [tableView dequeueReusableCellWithIdentifier: kDisplayCell_ID];
				if(sourceCell == nil)
					sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

				((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Use SSL", @"");
				((DisplayCell *)sourceCell).view = _sslSwitch;
				break;
			}

			sourceCell = [tableView dequeueReusableCellWithIdentifier: kCellTextField_ID];
			if(sourceCell == nil)
				sourceCell = [[[CellTextField alloc] initWithFrame: CGRectZero reuseIdentifier: kCellTextField_ID] autorelease];
			((CellTextField *)sourceCell).delegate = self; // so we can detect when cell editing starts

			switch(row)
			{
				case 0:
					((CellTextField *)sourceCell).view = _remoteNameTextField;
					_remoteNameCell = (CellTextField *)sourceCell;
					break;
				case 1:
					((CellTextField *)sourceCell).view = _remoteAddressTextField;
					_remoteAddressCell = (CellTextField *)sourceCell;
					break;
				case 2:
					((CellTextField *)sourceCell).view = _remotePortTextField;
					_remotePortCell = (CellTextField *)sourceCell;
					break;
				default:
					break;
			}
			break;
		case 1:
			sourceCell = [tableView dequeueReusableCellWithIdentifier: kCellTextField_ID];
			if(sourceCell == nil)
				sourceCell = [[[CellTextField alloc] initWithFrame: CGRectZero reuseIdentifier: kCellTextField_ID] autorelease];
			((CellTextField *)sourceCell).delegate = self; // so we can detect when cell editing starts

			switch(row)
			{
				case 0:
					((CellTextField *)sourceCell).view = _usernameTextField;
					_usernameCell = (CellTextField *)sourceCell;
					break;
				case 1:
					((CellTextField *)sourceCell).view = _passwordTextField;
					_passwordCell = (CellTextField *)sourceCell;
					break;
				default:
					break;
			}
			break;
		case 2:
			switch(row)
			{
				case 0:
					sourceCell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
					if (sourceCell == nil) 
						sourceCell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
					
					if(self.editing)
						sourceCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					
					if(_connector == kEnigma1Connector)
						TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"Enigma", @"");
					else if(_connector == kEnigma2Connector)
						TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"Enigma 2", @"");
					else if(_connector == kNeutrinoConnector)
						TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"Neutrino", @"");
					else if(_connector == kSVDRPConnector)
						TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"SVDRP", @"");
					else
						TABLEVIEWCELL_TEXT(sourceCell) = @"???";
					
					_connectorCell = sourceCell;
					break;
				case 1:
					sourceCell = [tableView dequeueReusableCellWithIdentifier: kDisplayCell_ID];
					if(sourceCell == nil)
						sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Single Bouquet", @"");
					((DisplayCell *)sourceCell).view = _singleBouquetSwitch;
					break;
				case 2:
					sourceCell = [tableView dequeueReusableCellWithIdentifier: kDisplayCell_ID];
					if(sourceCell == nil)
						sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
					
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Advanced Remote", @"");
					((DisplayCell *)sourceCell).view = _advancedRemoteSwitch;
					break;
			}
			break;
		case 3:
			sourceCell = [tableView dequeueReusableCellWithIdentifier: kDisplayCell_ID];
			if(sourceCell == nil)
				sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

			if(_connectionIndex == [RemoteConnectorObject getConnectedId])
				row++;

			switch(row)
			{
				case 0:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Connect", @"");
					((DisplayCell *)sourceCell).view = _connectButton;
					break;
				case 1:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Make Default", @"");
					((DisplayCell *)sourceCell).view = _makeDefaultButton;
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

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger row = indexPath.row;
	if(self.editing && indexPath.section == 2 && row == 0)
	{
		ConnectorViewController *targetViewController = [ConnectorViewController withConnector: _connector];
		[targetViewController setDelegate: self];
		[self.navigationController pushViewController: targetViewController animated: YES];
	}
	else if(indexPath.section == 3)
	{
		if(_connectionIndex == [RemoteConnectorObject getConnectedId])
			row++;

		if(row == 0)
			[self doConnect: nil];
		else
			[self makeDefault: nil];
	}

	// We don't want any actual response :-)
    return nil;
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management

/* stop editing other cells when starting another one */
- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	// notify other cells to end editing
	if([cell isEqual: _remoteNameCell])
	{
		[_remoteAddressCell stopEditing];
		[_remotePortCell stopEditing];
		[_usernameCell stopEditing];
		[_passwordCell stopEditing];
	}
	else if([cell isEqual: _remotePortCell])
	{
		[_remoteNameCell stopEditing];
		[_remoteAddressCell stopEditing];
		[_usernameCell stopEditing];
		[_passwordCell stopEditing];
	}
	else if([cell isEqual: _remoteAddressCell])
	{
		[_remoteNameCell stopEditing];
		[_remotePortCell stopEditing];
		[_usernameCell stopEditing];
		[_passwordCell stopEditing];
	}
	else
		[_remoteAddressCell stopEditing];

	// NOTE: _usernameCell & _passwordCell will track this themselves

	return self.editing;
}

/* cell stopped editing */
- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	/*!
	 @note We're only interested in _usernameCell and _passwordCell since
	 those might have messed with our view.
	 */
	if(([cell isEqual: _usernameCell] && ! _passwordCell.isInlineEditing)
		|| ([cell isEqual: _passwordCell] && !_usernameCell.isInlineEditing))
	{
        // Restore the position of the main view if it was animated to make room for the keyboard.
        if  (self.view.frame.origin.y < 0)
		{
            [self setViewMovedUp:NO];
        }
    }
}

/* Animate the entire view up or down, to prevent the keyboard from covering the text field. */
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

/* keyboard about to show */
- (void)keyboardWillShow:(NSNotification *)notif
{
	/*!
	 @note The keyboard will be shown. If the user is editing the username or password, adjust
	 the display so that the field will not be covered by the keyboard.
	 */
	if(_usernameCell.isInlineEditing || _passwordCell.isInlineEditing)
	{
		if(self.view.frame.origin.y >= 0)
			[self setViewMovedUp:YES];
	}
	else if(self.view.frame.origin.y < 0)
		[self setViewMovedUp:NO];
}

#pragma mark - UIViewController delegate methods

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
    // watch the keyboard so we can adjust the user interface if necessary.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
												name:UIKeyboardWillShowNotification
												object:self.view.window];

	[super viewWillAppear: animated];
}

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
												name:UIKeyboardWillShowNotification
												object:nil]; 

	[super viewWillDisappear: animated];
}

@end
