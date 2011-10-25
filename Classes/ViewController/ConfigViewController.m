//
//  ConfigViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "ConfigViewController.h"

#import "RemoteConnector.h"
#import "RemoteConnectorObject.h"
#import "Constants.h"
#import "UITableViewCell+EasyInit.h"

#import "DisplayCell.h"

/*!
 @brief Mapping connector -> default port
 */
static const NSInteger connectorPortMap[kMaxConnector][2] = {
	{80, 443}, // kEnigma2Connector
	{80, 443}, // kEnigma1Connector
	{80, 443}, // kNeutrinoConnector
	{2001, 2001}, // kSVDRPConnector
};

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

/*!
 @brief ssl value was changed.
 @param sender ui element
 */
- (void)sslChanged:(id)sender;



/*!
 @brief "Make Default" Button.
 */
@property (nonatomic,retain) UIButton *makeDefaultButton;

/*!
 @brief "Connect" Button.
 */
@property (nonatomic,retain) UIButton *connectButton;

@property (nonatomic,retain) MBProgressHUD *progressHUD;
@end

/*!
 @brief Keyboard offset.
 The amount of vertical shift upwards to keep the text field in view as the keyboard appears.
 */
#define kOFFSET_FOR_KEYBOARD                                   150

/*! @brief The duration of the animation for the view shift. */
#define kVerticalOffsetAnimationDuration               (CGFloat)0.30


@implementation ConfigViewController

@synthesize connectionIndex = _connectionIndex;
@synthesize makeDefaultButton = _makeDefaultButton;
@synthesize connectButton = _connectButton;
@synthesize progressHUD = progressHUD;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Configuration", @"Default title of ConfigViewController");
		_mustSave = NO;
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
#if INCLUDE_FEATURE(Enigma2)
																[NSNumber numberWithInteger:
																	kEnigma2Connector], kConnector,
#elif INCLUDE_FEATURE(Enigma)
																[NSNumber numberWithInteger:
																	kEnigma1Connector], kConnector,
#elif INCLUDE_FEATURE(Neutrino)
																[NSNumber numberWithInteger:
																	kNeutrinoConnector], kConnector,
#elif INCLUDE_FEATURE(SVDRP)
																[NSNumber numberWithInteger:
																	kSVDRPConnector], kConnector,
#else
	#warning No connector included, shame on you.
#endif
																nil];
	configViewController.connectionIndex = -1;

	return configViewController;
}

/* dealloc */
- (void)dealloc
{
	((UITableView *)self.view).delegate = nil;
	((UITableView *)self.view).dataSource = nil;

	SafeRetainAssign(_connection, nil);
	UnsetCellAndDelegate(_remoteNameCell);
	UnsetCellAndDelegate(_remoteAddressCell);
	UnsetCellAndDelegate(_remotePortCell);
	UnsetCellAndDelegate(_usernameCell);
	UnsetCellAndDelegate(_passwordCell);

	SafeRetainAssign(_remoteNameTextField, nil);
	SafeRetainAssign(_remoteAddressTextField, nil);
	SafeRetainAssign(_remotePortTextField, nil);
	SafeRetainAssign(_usernameTextField, nil);
	SafeRetainAssign(_passwordTextField, nil);
	SafeRetainAssign(_singleBouquetSwitch, nil);
	SafeRetainAssign(_advancedRemoteSwitch, nil);
	SafeRetainAssign(_nowNextSwitch, nil);
	SafeRetainAssign(_sslSwitch, nil);

	SafeDestroyButton(_makeDefaultButton);
	SafeDestroyButton(_connectButton);

	progressHUD.delegate = nil;
	SafeRetainAssign(progressHUD, nil);

	[super dealloc];
}

- (NSDictionary *)connection
{
	return _connection;
}

- (void)setConnection:(NSMutableDictionary *)con
{
	if(_connection == con) return;
	SafeRetainAssign(_connection, con);

	if(_remoteAddressTextField) // check if initialized
	{
		_remoteAddressTextField.text = [con objectForKey:kRemoteHost];
		_remotePortTextField.text = [[con objectForKey:kPort] integerValue] ? [[con objectForKey:kPort] stringValue] : nil;
		_usernameTextField.text = [con objectForKey:kUsername];
		_passwordTextField.text = [con objectForKey:kPassword];
		_sslSwitch.on = [[con objectForKey:kSSL] boolValue];
		_advancedRemoteSwitch.on = [[con objectForKey:kAdvancedRemote] boolValue];

		[self connectorSelected:[con objectForKey:kConnector]];
		[(UITableView *)self.view reloadData];
	}
}

- (BOOL)mustSave
{
	return _mustSave;
}

- (void)setMustSave:(BOOL)mustSave
{
	_mustSave = mustSave;

	UIAlertView *notification = [[UIAlertView alloc]
								 initWithTitle:NSLocalizedString(@"Need Help?", @"Title of Alert suggesting autoconfiguration.")
									   message:NSLocalizedString(@"To simplify configuration, this application can try to reach your STB using known default configurations.\nTry this now?", @"Message of Alert suggesting autoconfiguration.")
									  delegate:self
							 cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
							 otherButtonTitles:NSLocalizedString(@"Search", @"Button initiating autoconfiguration."), nil];
	[notification performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES]; // no idea what thread we are on, so force doing it NOW on the main thread
	[notification release];
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

	// Connector
	_connector = [[_connection objectForKey: kConnector] integerValue];

	// Remote Name
	NSString *remoteName = [_connection objectForKey: kRemoteName];
	if(remoteName == nil) // Work around unset property
		remoteName = @"";
	_remoteNameTextField = [[self create_TextField] retain];
	_remoteNameTextField.placeholder = NSLocalizedString(@"<address: e.g. 192.168.1.10>", @"");
	_remoteNameTextField.text = [[remoteName copy] autorelease];

	// Remote Address
	_remoteAddressTextField = [[self create_TextField] retain];
	_remoteAddressTextField.placeholder = NSLocalizedString(@"<address: e.g. 192.168.1.10>", @"");
	_remoteAddressTextField.text = [[[_connection objectForKey: kRemoteHost] copy] autorelease];
	_remoteAddressTextField.keyboardType = UIKeyboardTypeURL;

	// SSL
	_sslSwitch = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, kSwitchButtonWidth, kSwitchButtonHeight)];
	_sslSwitch.on = [[_connection objectForKey: kSSL] boolValue];
	_sslSwitch.backgroundColor = [UIColor clearColor];
	[_sslSwitch addTarget:self action:@selector(sslChanged:) forControlEvents:UIControlEventValueChanged];

	// Remote Port
	const NSNumber *port = [_connection objectForKey: kPort];
	_remotePortTextField = [[self create_TextField] retain];
	_remotePortTextField.placeholder = [NSString stringWithFormat:NSLocalizedString(@"<port: usually %d>", @"Placeholder text for remote port field."), connectorPortMap[_connector][_sslSwitch.on]];
	_remotePortTextField.text = [port integerValue] ? [port stringValue] : nil;
	_remotePortTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation; // NOTE: we lack a better one :-)

	// Username
	_usernameTextField = [[self create_TextField] retain];
	_usernameTextField.placeholder = NSLocalizedString(@"<username: usually root>", @"");
	_usernameTextField.text = [[[_connection objectForKey: kUsername] copy] autorelease];

	// Password
	_passwordTextField = [[self create_TextField] retain];
	_passwordTextField.placeholder = NSLocalizedString(@"<password: usually dreambox>", @"");
	_passwordTextField.text = [[[_connection objectForKey: kPassword] copy] autorelease];
	_passwordTextField.secureTextEntry = YES;

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

	// Now/Next switch
	_nowNextSwitch = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, kSwitchButtonWidth, kSwitchButtonHeight)];
	_nowNextSwitch.on = [[_connection objectForKey: kShowNowNext] boolValue];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_singleBouquetSwitch.backgroundColor = [UIColor clearColor];
	_advancedRemoteSwitch.backgroundColor = [UIColor clearColor];
	_nowNextSwitch.backgroundColor = [UIColor clearColor];

	[self setEditing:YES animated:NO];
}

- (void)viewDidUnload
{
	UnsetCellAndDelegate(_remoteNameCell);
	UnsetCellAndDelegate(_remoteAddressCell);
	UnsetCellAndDelegate(_remotePortCell);
	UnsetCellAndDelegate(_usernameCell);
	UnsetCellAndDelegate(_passwordCell);

	SafeRetainAssign(_remoteNameTextField, nil);
	SafeRetainAssign(_remoteAddressTextField, nil);
	SafeRetainAssign(_remotePortTextField, nil);
	SafeRetainAssign(_usernameTextField, nil);
	SafeRetainAssign(_passwordTextField, nil);
	SafeRetainAssign(_singleBouquetSwitch, nil);
	SafeRetainAssign(_advancedRemoteSwitch, nil);
	SafeRetainAssign(_nowNextSwitch, nil);
	SafeRetainAssign(_sslSwitch, nil);

	SafeDestroyButton(_makeDefaultButton);
	SafeDestroyButton(_connectButton);

	[super viewDidUnload];
}

/* (un)set editing */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	if(!editing)
	{
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
			[_connection setObject: _nowNextSwitch.on ? @"YES" : @"NO" forKey: kShowNowNext];
			[_connection setObject: _sslSwitch.on ? @"YES" : @"NO" forKey: kSSL];

			if(!_remoteAddressTextField.text.length)
			{
				UIAlertView *notification = [[UIAlertView alloc]
											 initWithTitle:NSLocalizedString(@"Error", @"")
											 message:NSLocalizedString(@"A connection needs at least a hostname.", @"No hostname entered in ConfigView.")
											 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[notification show];
				[notification release];
				return;
			}

			NSMutableArray *connections = [RemoteConnectorObject getConnections];
			if(_connectionIndex == -1)
			{
				_connectionIndex = [connections count];
				[connections addObject: _connection];
				// FIXME: ugly!
				if(_connectionIndex != [[NSUserDefaults standardUserDefaults] integerForKey: kActiveConnection] || _connectionIndex != [RemoteConnectorObject getConnectedId])
				{
					const NSInteger numberOfRowsInSection = [(UITableView *)self.view numberOfRowsInSection:2];
					const NSInteger newNumberOfRowsInSection = [self tableView:(UITableView *)self.view numberOfRowsInSection:2];
					if(numberOfRowsInSection != newNumberOfRowsInSection) // XXX: seen a weird crash because of this, handle it
					{
#if IS_DEBUG()
						[NSException raise:@"numberOfRowsDidNotMatch" format:@"was %d, is now %d. _connector %d, kConnector %@", numberOfRowsInSection, newNumberOfRowsInSection, _connector, [[_connection objectForKey:kConnector] stringValue]];
#endif
						[(UITableView *)self.view reloadData];
					}
					else
					{
						[(UITableView *)self.view beginUpdates];
						[(UITableView *)self.view insertSections: [NSIndexSet indexSetWithIndex: 3]
												withRowAnimation: UITableViewRowAnimationFade];
						[(UITableView *)self.view endUpdates];
					}
				}
			}
			else
			{
				[connections replaceObjectAtIndex: _connectionIndex withObject: _connection];

				// Reconnect because changes won't be applied otherwise
				if(_connectionIndex == [RemoteConnectorObject getConnectedId])
				{
					[RemoteConnectorObject connectTo: _connectionIndex];
				}
			}

			// post notification
			[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
		}

		[self.navigationItem setLeftBarButtonItem: nil animated: YES];

		[_remoteNameCell stopEditing];
		[_remoteAddressCell stopEditing];
		[_remotePortCell stopEditing];
		[_usernameCell stopEditing];
		[_passwordCell stopEditing];
		_singleBouquetSwitch.enabled = NO;
		_advancedRemoteSwitch.enabled = NO;
		_nowNextSwitch.enabled = NO;
		_sslSwitch.enabled = NO;

		UITableViewCell *connectorCell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
		if(connectorCell)
			connectorCell.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		_shouldSave = YES;
		_singleBouquetSwitch.enabled = YES;
		_advancedRemoteSwitch.enabled = YES;
		_nowNextSwitch.enabled = YES;
		_sslSwitch.enabled = YES;
		UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(cancelEdit:)];
		[self.navigationItem setLeftBarButtonItem: cancelButtonItem animated: YES];
		[cancelButtonItem release];

		UITableViewCell *connectorCell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
		if(connectorCell)
			connectorCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

#if IS_DEBUG()
	NSLog(@"[ConfigViewController setEditing::] about to call [super setEditing::]");
	// NOTE: I assume the problem is that we are already (or currently being) deallocated, what to do?
#endif
	[super setEditing: editing animated: animated];

	/*_makeDefaultButton.enabled = editing;
	 _connectButton.enabled = editing;*/
}

/* cancel and close */
- (void)cancelEdit: (id)sender
{
	if(_mustSave && ![[RemoteConnectorObject getConnections] count])
	{
		UIAlertView *notification = [[UIAlertView alloc]
									initWithTitle:NSLocalizedString(@"Error", @"")
									message:NSLocalizedString(@"You need to configure this application before you can use it.", @"")
									delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
		[notification release];
	}
	else
	{
		_shouldSave = NO;
		[self setEditing: NO animated: YES];
		[self.navigationController popViewControllerAnimated: YES];
	}
}

/* "make default" button pressed */
- (void)makeDefault: (id)sender
{
	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber *activeConnection = [NSNumber numberWithInteger: _connectionIndex];
	const NSInteger connectedId = [RemoteConnectorObject getConnectedId];

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
	else
	{
		// connected to different host than before
		if(_connectionIndex != connectedId)
		{
			const NSError *error = nil;
			const BOOL doAbort = ![[RemoteConnectorObject sharedRemoteConnector] isReachable:&error];
			// error without doAbort means e.g. old version
			if(error)
			{
				UIAlertView *notification = [[UIAlertView alloc]
											 initWithTitle:doAbort ? NSLocalizedString(@"Error", @"") : NSLocalizedString(@"Warning", @"")
											 message:[error localizedDescription]
											 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[notification show];
				[notification release];
				if(doAbort)
				{
					[RemoteConnectorObject connectTo:connectedId];
					return;
				}
			}
		}
	}
	NSInteger numberOfSections = [(UITableView *)self.view numberOfSections];
#if IS_DEBUG()
	NSInteger curDefault = [[stdDefaults objectForKey:kActiveConnection] integerValue];
#endif
	[stdDefaults setObject: activeConnection forKey: kActiveConnection];

	if(numberOfSections == 4)
	{
		[(UITableView *)self.view beginUpdates];
		[(UITableView *)self.view deleteSections:[NSIndexSet indexSetWithIndex:3]
								withRowAnimation:UITableViewRowAnimationFade];
		[(UITableView *)self.view endUpdates];
	}
	else if(numberOfSections != 3) // NOTE: we also expect "3" if this was fired multiple times
	{
#if IS_DEBUG()
		[NSException raise:@"InvalidSectionCountOnMakeDefault" format:@"numberOfSections was %d, expected 4. kActiveConnection was %d, _connectionIndex is %d, connected was %d", numberOfSections, curDefault, _connectionIndex, connectedId];
#else
		[(UITableView *)self.view reloadData];
#endif
	}
	
	// post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
}

/* "connect" button pressed */
- (void)doConnect: (id)sender
{
	const NSInteger connectedId = [RemoteConnectorObject getConnectedId];

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
	else
	{
		const NSError *error = nil;
		const BOOL doAbort = ![[RemoteConnectorObject sharedRemoteConnector] isReachable:&error];
		// error without doAbort means e.g. old version
		if(error)
		{
			UIAlertView *notification = [[UIAlertView alloc]
										 initWithTitle:doAbort ? NSLocalizedString(@"Error", @"") : NSLocalizedString(@"Warning", @"")
									message:[error localizedDescription]
									delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[notification show];
			[notification release];
			if(doAbort)
			{
				[RemoteConnectorObject connectTo:connectedId];
				return;
			}
		}
	}
	const NSInteger numberOfRowsInSection = [(UITableView *)self.view numberOfRowsInSection:3];
	const BOOL isDefault = (_connectionIndex == [stdDefaults integerForKey: kActiveConnection]);

	if(isDefault && numberOfRowsInSection == 1)
	{
		[(UITableView *)self.view beginUpdates];
		[(UITableView *)self.view deleteSections: [NSIndexSet indexSetWithIndex: 3]
									withRowAnimation: UITableViewRowAnimationFade];
		[(UITableView *)self.view endUpdates];
	}
	else if(!isDefault && numberOfRowsInSection == 2)
	{
		[(UITableView *)self.view beginUpdates];
		[(UITableView *)self.view
				deleteRowsAtIndexPaths: [NSArray arrayWithObject:
											[NSIndexPath indexPathForRow:0 inSection:3]]
				withRowAnimation: UITableViewRowAnimationFade];
		[(UITableView *)self.view endUpdates];
	}
	else
	{
#if IS_DEBUG()
		[NSException raise:@"InvalidRowCountOnDoConnect" format:@"%@, numberOfRowsInSection %d", isDefault ? @"is default" : @"not default", numberOfRowsInSection];
#else
		[(UITableView *)self.view reloadData];
#endif
	}

	// post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
}

- (void)sslChanged:(id)sender
{
	// update port placeholder
	_remotePortTextField.placeholder = [NSString stringWithFormat:NSLocalizedString(@"<port: usually %d>", @"Placeholder text for remote port field."), connectorPortMap[_connector][_sslSwitch.on]];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
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

	UITableViewCell *connectorCell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
	if(_connector == kEnigma1Connector)
		TABLEVIEWCELL_TEXT(connectorCell) = NSLocalizedString(@"Enigma", @"");
	else if(_connector == kEnigma2Connector)
		TABLEVIEWCELL_TEXT(connectorCell) = NSLocalizedString(@"Enigma 2", @"");
	else if(_connector == kNeutrinoConnector)
		TABLEVIEWCELL_TEXT(connectorCell) = NSLocalizedString(@"Neutrino", @"");
	else if(_connector == kSVDRPConnector)
		TABLEVIEWCELL_TEXT(connectorCell) = NSLocalizedString(@"SVDRP", @"");
	else
		TABLEVIEWCELL_TEXT(connectorCell) = @"???";

	// update port placeholder
	_remotePortTextField.placeholder = [NSString stringWithFormat:NSLocalizedString(@"<port: usually %d>", @"Placeholder text for remote port field."), connectorPortMap[_connector][_sslSwitch.on]];
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
			 @brief Add "single bouquet", "advanced remote" & "now/next" switch for Enigma2
			  based STBs on iPhone, but iPad does not know single bouquet mode, so there is
			  only three rows.
			 @note Actually this is an ugly hack but I really wanted this feature :P
			 */
			if(_connector == kEnigma2Connector)
				return (IS_IPAD()) ? 3 : 4;
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
				sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];

				((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Use SSL", @"");
				((DisplayCell *)sourceCell).view = _sslSwitch;
				break;
			}

			sourceCell = [CellTextField reusableTableViewCellInView:tableView withIdentifier:kCellTextField_ID];
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
			sourceCell = [CellTextField reusableTableViewCellInView:tableView withIdentifier:kCellTextField_ID];
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
					sourceCell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];

#if INCLUDE_FEATURE(Multiple_Connectors)
					if(self.editing)
						sourceCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
#endif
					
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
					TABLEVIEWCELL_FONT(sourceCell) = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				case 1:
					sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];

					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Now/Next in Servicelist", @"");
					((DisplayCell *)sourceCell).view = _nowNextSwitch;
					break;
				case 2:
					if(!IS_IPAD())
					{
						sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];

						((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Single Bouquet", @"");
						((DisplayCell *)sourceCell).view = _singleBouquetSwitch;
						break;
					}
					/* FALL THROUGH */
				case 3:
					sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];

					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Advanced Remote", @"");
					((DisplayCell *)sourceCell).view = _advancedRemoteSwitch;
					break;
			}
			break;
		case 3:
			sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];

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
#if INCLUDE_FEATURE(Multiple_Connectors)
		ConnectorViewController *targetViewController = [ConnectorViewController withConnector: _connector];
		[targetViewController setDelegate: self];
		if(IS_IPAD())
		{
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:targetViewController];
			navController.modalPresentationStyle = targetViewController.modalPresentationStyle;
			navController.modalTransitionStyle = targetViewController.modalTransitionStyle;
			[self.navigationController presentModalViewController:navController animated:YES];
			[navController release];
		}
		else
		{
			[self.navigationController pushViewController: targetViewController animated: YES];
		}
#endif
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
	if(IS_IPAD())
	{
		/*!
		 @note We're only interested in _usernameCell and _passwordCell since
		 those might have messed with our view.
		 */
		if(([cell isEqual: _usernameCell] && ! _passwordCell.isInlineEditing)
			|| ([cell isEqual: _passwordCell] && !_usernameCell.isInlineEditing))
		{
			// Restore the position of the main view if it was animated to make room for the keyboard.
			if(self.view.frame.origin.y < 0)
			{
				[self setViewMovedUp:NO];
			}
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
	if(IS_IPAD())
	{
		if(!UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) return;
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
	else
	{
		NSIndexPath *indexPath;
		UITableViewScrollPosition scrollPosition = UITableViewScrollPositionMiddle;
		if(_remoteNameCell.isInlineEditing)
			indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
		else if(_remoteAddressCell.isInlineEditing)
			indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
		else if(_remotePortCell.isInlineEditing)
			indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
		else if(_usernameCell.isInlineEditing)
			indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
		else if(_passwordCell.isInlineEditing)
			indexPath = [NSIndexPath indexPathForRow:1 inSection:1];
		else return;

		if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
			scrollPosition = UITableViewScrollPositionTop;
		[(UITableView *)self.view scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
	}
		
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

#pragma mark ConfigListDelegate

- (void)connectionSelected:(NSMutableDictionary *)dictionary
{
	self.connection = dictionary;
}

#pragma mark AutoConfiguration

- (void)doAutoConfiguration
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview: progressHUD];
    progressHUD.delegate = self;
    [progressHUD setLabelText:NSLocalizedString(@"Searching…", @"Label of Progress HUD during AutoConfiguration")];
    [progressHUD setMode:MBProgressHUDModeIndeterminate];
    [progressHUD show:YES];
    progressHUD.taskInProgress = YES;

	NSArray *connections = [RemoteConnectorObject autodetectConnections];

	progressHUD.taskInProgress = NO;
	[progressHUD hide:YES];

	NSUInteger len = connections.count;
	if(len == 0)
	{
		const UIAlertView *notification = [[UIAlertView alloc]
									 initWithTitle:NSLocalizedString(@"Error", @"")
									 message:NSLocalizedString(@"Unable to find valid connection data.", @"")
									 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
		[notification release];
	}
	else if(len == 1)
	{
		NSMutableDictionary *con = [[connections objectAtIndex:0] mutableCopy];
		self.connection = con;
		[con release];
	}
	else
	{
		ConnectionListController *tv = [ConnectionListController newWithConnections:connections andDelegate:self];
		if(IS_IPAD())
		{
			UIViewController *nc = [[UINavigationController alloc] initWithRootViewController:tv];
			nc.modalPresentationStyle = tv.modalPresentationStyle;
			nc.modalTransitionStyle = tv.modalTransitionStyle;
			[self.navigationController presentModalViewController:nc animated:YES];
			[nc release];
		}
		else
		{
			[self.navigationController pushViewController:tv animated:YES];
		}
		[tv release];
	}

	[pool release];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate
#pragma mark -

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [progressHUD removeFromSuperview];
    self.progressHUD = nil;
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == alertView.firstOtherButtonIndex)
	{
		[NSThread detachNewThreadSelector:@selector(doAutoConfiguration) toTarget:self withObject:nil];
	}
}

@end
