//
//  ConfigListController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "ConfigListController.h"

#import "Constants.h"
#import "NSArray+ArrayFromData.h"
#import "NSData+Base64.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"
#import "UIDevice+SystemVersion.h"

#import <TableViewCell/DisplayCell.h>

#import <ViewController/AboutDreamoteViewController.h>
#import <ViewController/ConfigViewController.h>
#import <ListController/ConnectionListController.h>
#import <ListController/SimpleSingleSelectionListController.h>
#import <ListController/ServiceZapListController.h>

#import "SSKManager.h"

enum rowTags
{
	kMultiEPGRowTag = 99,
	kTimeoutRowTag = 100,
	kHistoryLengthRowTag = 101,
	kThemeRowTag = 102,
	kZapModeRowTag = 103,
};

enum sectionIds
{
	connectionSection = 0,
	settingsSection = 1,
	buttonSection = 2,
	purchaseSection = 3,
	maxSection = 4,
};

enum settingsRows
{
	simpleRemoteRow = 0,
	separateEventsRow,
	vibrationRow,
	themeRow,
	zapModeRow,
	timeoutRow,
	historyLengthRow,
    customActionRow,
#if IS_FULL()
	multiEpgRow,
#endif
	settingsRowMax,
};


#pragma mark - UIActionSheet with block callback
typedef void (^dismiss_block_t)(UIAlertView *alertView, NSInteger buttonIndex);
@interface UIBlockAlertView : UIAlertView<UIAlertViewDelegate>
+ (UIBlockAlertView *)alertViewWithTitle:(NSString *)title
								 message:(NSString *)message
					   cancelButtonTitle:(NSString *)cancelButtonTitle
					   otherButtonTitles:(NSArray *)buttonTitles
							   onDismiss:(dismiss_block_t)onDismiss;
@property (nonatomic, copy) dismiss_block_t onDismiss;
@end

@implementation UIBlockAlertView
@synthesize onDismiss;
+ (UIBlockAlertView *)alertViewWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)buttonTitles onDismiss:(dismiss_block_t)onDismiss
{
	UIBlockAlertView *view = [[UIBlockAlertView alloc] initWithTitle:title
															 message:message
															delegate:nil
												   cancelButtonTitle:cancelButtonTitle
												   otherButtonTitles:nil];
	for(NSString* thisButtonTitle in buttonTitles)
		[view addButtonWithTitle:thisButtonTitle];

	view.onDismiss = onDismiss;
	view.delegate = view;
	[view show];
	return view;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	((UIBlockAlertView *)alertView).onDismiss(alertView, buttonIndex);
}
@end

#pragma mark - ConfigListController

/*!
 @brief Private functions of ConfigListController.
 */
@interface ConfigListController()
/*!
 @brief Utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell
 to be used for a given index path.

 @param indexPath IndexPath
 @return UITableViewCell instance
 */
- (UITableViewCell *)obtainTableCellForIndexPath:(NSIndexPath *)indexPath;
- (void)simpleRemoteChanged:(id)sender;
- (void)vibrationChanged:(id)sender;
- (void)separateEventsChanged:(id)sender;
- (void)rereadData:(NSNotification *)note;
- (void)productsFetched:(NSNotification *)note;

- (void)purchaseSectionSelectedAtIndexPath:(NSIndexPath *)indexPath;

@property (nonatomic,strong) MBProgressHUD *progressHUD;
@end

/*!
 @brief AutoConfiguration related methods of ConfigListController.
 */
@interface ConfigListController(AutoConfiguration)
/*!
 @brief Start AutoConfiguration process.
 */
- (void)doAutoConfiguration;
@end

@implementation ConfigListController

@synthesize progressHUD;
@synthesize tableView = _tableView;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Configuration", @"Default Title of ConfigListController");
		_connections = [RemoteConnectorObject getConnections];
		purchasables = [SSKManager sharedManager].purchasables;

		// listen to changes in available connections
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rereadData:) name:kReconnectNotification object:nil];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self stopObservingThemeChanges];

	_tableView.delegate = nil;
	_tableView.dataSource = nil;
    UnsetCellAndDelegate(_customActionTextField);
	progressHUD.delegate = nil;
}

/* layout */
- (void)loadView
{
	const BOOL isIpad = IS_IPAD();
	_tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.allowsSelectionDuringEditing = YES;
	//_tableView.rowHeight = 48.0;
	//_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	_tableView.autoresizesSubviews = YES;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	if(isIpad)
		_tableView.backgroundView = [[UIView alloc] init];

	self.view = _tableView;

	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	if(!isIpad)
	{
		// RC Vibration
		_vibrateInRC = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
		_vibrateInRC.on = [stdDefaults boolForKey: kVibratingRC];
		[_vibrateInRC addTarget:self action:@selector(vibrationChanged:) forControlEvents:UIControlEventValueChanged];
		_vibrateInRC.backgroundColor = [UIColor clearColor];
	}

	// Simple remote
	_simpleRemote = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_simpleRemote.on = [stdDefaults boolForKey: kPrefersSimpleRemote];
	[_simpleRemote addTarget:self action:@selector(simpleRemoteChanged:) forControlEvents:UIControlEventValueChanged];
	_simpleRemote.backgroundColor = [UIColor clearColor];

	// Simple remote
	_sepEventsByDay = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_sepEventsByDay.on = [stdDefaults boolForKey:kSeparateEpgByDay];
	[_sepEventsByDay addTarget:self action:@selector(separateEventsChanged:) forControlEvents:UIControlEventValueChanged];
	_sepEventsByDay.backgroundColor = [UIColor clearColor];

	// add edit button
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    _customActionTextField = [self create_TextField];
    _customActionTextField.placeholder = NSLocalizedString(@"<url to custom action>", @"Placeholder for custom urlaction.");
    _customActionTextField.text = [stdDefaults stringForKey:kCustomACtion];
    [_customActionTextField addTarget:self action:@selector(customActionChanged:) forControlEvents:UIControlEventEditingDidEnd];
	[self theme];
}

- (void)theme
{
	if([UIDevice newerThanIos:5.0f])
	{
		UIColor *tintColor = [DreamoteConfiguration singleton].tintColor;
		_vibrateInRC.onTintColor = tintColor;
		_simpleRemote.onTintColor = tintColor;
		_sepEventsByDay.onTintColor = tintColor;
	}
	[super theme];
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
    
	return returnTextField;
}


- (void)viewDidLoad
{
	[self startObservingThemeChanges];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsFetched:) name:kProductFetchedNotification object:nil];
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[self stopObservingThemeChanges];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsFetched:) name:kProductFetchedNotification object:nil];
	_vibrateInRC = nil;
	_simpleRemote = nil;
	_sepEventsByDay = nil;
	_tableView = nil;

	[super viewDidUnload];
}

/* (un)set editing */
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing: editing animated: animated];

	// Animate if requested
	if(animated)
	{
		if([self tableView:_tableView numberOfRowsInSection:0] == [_tableView numberOfRowsInSection:0])
		{
			// ignore
		}
		else if(editing)
		{
			[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]
							  withRowAnimation:UITableViewRowAnimationFade];
		}
		else
		{
			[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]
							  withRowAnimation:UITableViewRowAnimationFade];
		}
	}
	else
	{
		[_tableView reloadData];
	}
	[_tableView setEditing: editing animated: animated];
}

- (void)simpleRemoteChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool: _simpleRemote.on forKey: kPrefersSimpleRemote];

	// we need to post a notification so the main view reloads the rc
	[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
}

- (void)customActionChanged:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setValue: _customActionTextField.text forKey: kCustomACtion];
}

- (void)vibrationChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool: _vibrateInRC.on forKey: kVibratingRC];
}

- (void)separateEventsChanged:(id)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:_sepEventsByDay.on forKey:kSeparateEpgByDay];
}

- (void)rereadData:(NSNotification *)note
{
	if(![self isViewLoaded] || self.view.superview)
		return;

	_connections = [RemoteConnectorObject getConnections];

	// just in case, read them too
	[_vibrateInRC setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kVibratingRC]];
	[_simpleRemote setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kPrefersSimpleRemote]];
	[_sepEventsByDay setOn:[[NSUserDefaults standardUserDefaults] boolForKey:kSeparateEpgByDay]];

	[_tableView reloadData];
}

- (void)productsFetched:(NSNotification *)note
{
	purchasables = [SSKManager sharedManager].purchasables;
	[_tableView reloadData];
}

- (void)doPurchase:(SSKProduct *)product
{
	[[SSKManager sharedManager] buyProduct:product
						 completionHandler:^(NSString *featureId)
	 {
		 progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
		 progressHUD.mode = MBProgressHUDModeCustomView;
		 progressHUD.labelText = NSLocalizedString(@"Purchase completed", @"In-App-Purchase was completed successfully");
		 [progressHUD hide:YES afterDelay:2];
#if INCLUDE_FEATURE(Ads)
		 if([featureId isEqualToString:kAdFreePurchase])
		 {
			 [[NSNotificationCenter defaultCenter] postNotificationName:kAdRemovalPurchased object:nil userInfo:nil];
		 }
#endif
	 }
							 cancelHandler:^(NSString *featureId)
	 {
		 [progressHUD hide:YES];
	 }
							  errorHandler:^(NSString *featureId, NSError *error)
	 {
#ifndef NDEBUG
		 NSLog(@"purchase error: %@", error);
#endif
		 NSString *title = [error localizedFailureReason];
		 NSString *message = [error localizedRecoverySuggestion];
		 if(!message && [error code] != 5001)
			 message = [error localizedDescription];
		 if(error.domain == sskErrorDomain && error.code == 100) // hide "double taps"
			 title = message = nil;
		 if(title || message)
		 {
			 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
															 message:message
															delegate:self
												   cancelButtonTitle:@"OK"
												   otherButtonTitles:nil];
			 [alert show];
		 }
		 [progressHUD hide:YES];
	 }];
}

- (void)purchaseSectionSelectedAtIndexPath:(NSIndexPath *)indexPath
{
	dispatch_block_t showHud = ^{
		progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
		[self.view addSubview:progressHUD];
		progressHUD.removeFromSuperViewOnHide = YES;
		[progressHUD setLabelText:NSLocalizedString(@"Working…", @"Label of Progress HUD in ConfigList when waiting for the AppStore")];
		[progressHUD setMode:MBProgressHUDModeIndeterminate];
		[progressHUD show:YES];
	};

	if(indexPath.row < (NSInteger)purchasables.count)
	{
		SSKProduct *product = [purchasables objectAtIndex:indexPath.row];
		if([product.productIdentifier isEqualToString:kServiceEditorPurchase] && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesServiceEditor])
		{
			[UIBlockAlertView alertViewWithTitle:NSLocalizedString(@"Warning", @"")
										 message:NSLocalizedString(@"The current connection does not support the Service Editor.\nPlease remember to install enigma2-plugin-extensions-webbouqueteditor.", @"Trying to purchase Service Editor but Plugin not found on the STB.")
							   cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
							   otherButtonTitles:[NSArray arrayWithObject:NSLocalizedString(@"Purchase", @"")]
									   onDismiss:^(UIAlertView *alertView, NSInteger buttonIndex)
			{
				if(buttonIndex == alertView.cancelButtonIndex)
				{
					// ignore
				}
				else
				{
					dispatch_async(dispatch_get_main_queue(), showHud);
					[self doPurchase:product];
				}
			}];
		}
		else
		{
			showHud();
			[self doPurchase:product];
		}
	}
#if IS_DEBUG()
	else if(indexPath.row == (NSInteger)purchasables.count + 1)
	{
		showHud();
		[[SSKManager sharedManager] removeAllKeychainData];
		[progressHUD hide:YES];
	}
#endif
	else
	{
		showHud();
		[[SSKManager sharedManager] restorePreviousPurchasesOnComplete:^(NSString *featureId)
		 {
			 progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-Checkmark.png"]];
			 progressHUD.mode = MBProgressHUDModeCustomView;
			 progressHUD.labelText = NSLocalizedString(@"Restore completed", @"In-App-Purchase were restored successfully");
			 [progressHUD hide:YES afterDelay:2];
		 }
																	  onError:^(NSString *featureId, NSError *error)
		 {
			 [progressHUD hide:YES];
			 NSLog(@"error %@, error code %d", error, error.code);
			 if(!error || error.domain != SKErrorDomain) return;
			 const UIAlertView *notification = [[UIAlertView alloc] initWithTitle:[error localizedFailureReason]
																		  message:[error localizedRecoverySuggestion]
																		 delegate:nil
																cancelButtonTitle:@"OK"
																otherButtonTitles:nil];
			 [notification performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
		 }];
	}
}

- (void)connectTo:(NSIndexPath *)indexPath
{
	const NSInteger connectedIdx = [RemoteConnectorObject getConnectedId];

	if(![RemoteConnectorObject connectTo:indexPath.row inBackground:NO])
	{
		// error connecting... what now?
		UIAlertView *notification = [[UIAlertView alloc]
									 initWithTitle:NSLocalizedString(@"Error", @"")
									 message:NSLocalizedString(@"Unable to connect to host.\nPlease restart the application.", @"")
									 delegate:nil
									 cancelButtonTitle:@"OK"
									 otherButtonTitles:nil];
		[notification show];
	}
	// did connect
	else
	{
		const NSError *error = nil;
		const BOOL doAbort = ![[RemoteConnectorObject sharedRemoteConnector] isReachable:&error];
		dispatch_block_t mainBlock = nil;
		// error without doAbort means e.g. old version
		if(error)
		{
			UIAlertView *notification = [[UIAlertView alloc]
										 initWithTitle:doAbort ? NSLocalizedString(@"Error", @"") : NSLocalizedString(@"Warning", @"")
										 message:[error localizedDescription]
										 delegate:nil
										 cancelButtonTitle:@"OK"
										 otherButtonTitles:nil];
			[notification show];
		}

		// not reachable
		if(doAbort)
		{
			[RemoteConnectorObject connectTo:connectedIdx inBackground:YES];
			mainBlock = ^{
				[_tableView deselectRowAtIndexPath:indexPath animated:YES];
			};
		}
		// connected to new host
		else if(connectedIdx != indexPath.row)
		{
			NSArray *reloads = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:connectedIdx inSection:0], indexPath, nil];
			mainBlock = ^{
				[_tableView reloadRowsAtIndexPaths:reloads withRowAnimation:UITableViewRowAnimationFade];
			};

			// post notification
			[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
		}
		// connected to same host
		else
		{
			mainBlock =^{
				[_tableView deselectRowAtIndexPath:indexPath animated:YES];
			};
		}
		if(mainBlock)
			dispatch_async(dispatch_get_main_queue(), mainBlock);
	}
}

#pragma mark -
#pragma mark TimeoutSelection
#pragma mark -

- (void)didSetTimeout
{
	NSInteger row = timeoutRow;
	if(IS_IPAD() && vibrationRow < timeoutRow)
		--row;
	NSIndexPath *idx = [NSIndexPath indexPathForRow:row inSection:settingsSection];

	[_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:idx] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -
#pragma mark SearchHistoryLengthEditorDelegate
#pragma mark -

- (void)didSetLength
{
	NSInteger row = historyLengthRow;
	if(IS_IPAD() && vibrationRow < historyLengthRow)
		--row;
	NSIndexPath *idx = [NSIndexPath indexPathForRow:row inSection:settingsSection];
	[_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:idx] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == settingsSection)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		if(cell.tag == kTimeoutRowTag
		   || cell.tag == kHistoryLengthRowTag
		   || cell.tag == kThemeRowTag
		   || cell.tag == kZapModeRowTag
#if IS_FULL()
		   || cell.tag == kMultiEPGRowTag
#endif
		   )
			return indexPath;

		return nil;
	}
	return indexPath;
}

/* row was selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.section == buttonSection)
	{
		if(indexPath.row == 0)
		{
			UIViewController *welcomeController = [[AboutDreamoteViewController alloc] initWithWelcomeType:welcomeTypeFull];
			[self presentModalViewController:welcomeController animated:YES];
		}
		else if(indexPath.row == 1)
		{
			progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
			progressHUD.delegate = self;
			[self.view addSubview: progressHUD];
			self.navigationItem.rightBarButtonItem.enabled = NO;
			[progressHUD setLabelText:NSLocalizedString(@"Searching…", @"Label of Progress HUD during AutoConfiguration")];
			[progressHUD setMode:MBProgressHUDModeIndeterminate];
			[progressHUD show:YES];
			progressHUD.taskInProgress = YES;

			[NSThread detachNewThreadSelector:@selector(doAutoConfiguration) toTarget:self withObject:nil];
		}
#if IS_LITE()
		else if(indexPath.row == 2)
		{
			NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
			NSData *data = [NSData dataWithContentsOfFile:[kConfigPath stringByExpandingTildeInPath]];
			NSString *importString = [data base64EncodedString];
			NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:
						@"dreaMote:///settings?import:%@&%@:%i&%@:%i&%@:%i&%@:%i&%@:%i&%@:%d&%@:%i",
										   importString,
										   kActiveConnection, [stdDefaults integerForKey:kActiveConnection],
										   kVibratingRC, [stdDefaults boolForKey: kVibratingRC],
										   kMessageTimeout, [stdDefaults integerForKey:kMessageTimeout],
										   kPrefersSimpleRemote, [stdDefaults boolForKey:kPrefersSimpleRemote],
										   kTimeoutKey, kTimeout,
										   kSearchHistoryLength, [stdDefaults integerForKey:kSearchHistoryLength],
										   kSeparateEpgByDay, [stdDefaults boolForKey:kSeparateEpgByDay]]];
			[[UIApplication sharedApplication] openURL:url];
		}
#endif
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else if(indexPath.section == connectionSection)
	{
		NSInteger upperBound = [_connections count];
		if(self.editing) ++upperBound;

		// FIXME: seen some crashlogs which supposedly ran into this case...
		if(indexPath.row < upperBound)
		{
			[RemoteConnectorObject cancelPendingOperations];

			// open ConfigViewController if editing
			if(self.editing)
			{
				// new connection
				if(indexPath.row == 0)
				{
					UIViewController *targetViewController = [ConfigViewController newConnection];
					[self.navigationController pushViewController: targetViewController animated: YES];
				}
				// edit existing one
				else
				{
					UIViewController *tvc = [ConfigViewController withConnection:[_connections objectAtIndex:indexPath.row-1] :indexPath.row-1];
					[self.navigationController pushViewController:tvc animated:YES];
				}
			}
			// else connect to this host
			else
			{
				progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
				[self.view addSubview:progressHUD];
				progressHUD.removeFromSuperViewOnHide = YES;
				[progressHUD setLabelText:NSLocalizedString(@"Connecting…", @"Label of Progress HUD when switching connections")];
				[progressHUD setMode:MBProgressHUDModeIndeterminate];
				[progressHUD showWhileExecuting:@selector(connectTo:) onTarget:self withObject:indexPath animated:YES];
			}
		}
		else
		{
			NSLog(@"ERROR: about to select out of bounds, aborting...");
		}
	}
	else if(indexPath.section == settingsSection)
	{
		const BOOL isIpad = IS_IPAD();
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		UIViewController *targetViewController = nil;

		if(cell.tag == kTimeoutRowTag)
		{
			TimeoutSelectionViewController *vc = [TimeoutSelectionViewController withTimeout:kTimeout];
			vc.delegate = self;
			if(isIpad)
			{
				targetViewController = [[UINavigationController alloc] initWithRootViewController:vc];
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
			}
			else
				targetViewController = vc;
		}
		else if(cell.tag == kHistoryLengthRowTag)
		{
			SearchHistoryLengthEditorController *vc = [SearchHistoryLengthEditorController withLength:[[NSUserDefaults standardUserDefaults] integerForKey:kSearchHistoryLength]];
			vc.delegate = self;
			if(isIpad)
			{
				targetViewController = [[UINavigationController alloc] initWithRootViewController:vc];
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
			}
			else
				targetViewController = vc;
		}
		else if(cell.tag == kThemeRowTag)
		{
			DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
			SimpleSingleSelectionListController *vc = [SimpleSingleSelectionListController withItems:[singleton themeNames]
																						andSelection:[DreamoteConfiguration singleton].currentTheme
																							andTitle:NSLocalizedString(@"Theme", @"Title for theme selection")];
			__block SimpleSingleSelectionListController *blockVc = vc;
			NSUInteger currentTheme = [DreamoteConfiguration singleton].currentTheme;
			vc.callback = ^(NSUInteger newSelection, BOOL isFinal, BOOL canceling)
			{
				if(!canceling)
				{
					[DreamoteConfiguration singleton].currentTheme = newSelection;

					if(!isIpad && !isFinal)
					{
						[blockVc theme];
						return NO;
					}

					NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
					[stdDefaults setObject:[NSNumber numberWithInteger:newSelection] forKey:kActiveTheme];
					[stdDefaults synchronize];
					[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
				}
				else if(!isIpad)
				{
					[DreamoteConfiguration singleton].currentTheme = currentTheme;
					[self.navigationController popToViewController:self animated:YES];
				}

				if(isIpad)
					[self dismissModalViewControllerAnimated:YES];
				return YES;
			};
			
			if(isIpad)
			{
				targetViewController = [[UINavigationController alloc] initWithRootViewController:vc];
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
			}
			else
				targetViewController = vc;
		}
		else if(cell.tag == kZapModeRowTag)
		{
			SimpleSingleSelectionListController *vc = [SimpleSingleSelectionListController withItems:[ServiceZapListController playerNames]
																						andSelection:[ServiceZapListController indexForZapAction:[[NSUserDefaults standardUserDefaults] integerForKey:kZapModeDefault]]
																							andTitle:NSLocalizedString(@"Default Zap-Type", @"Title of default zap type selection")];
			vc.callback = ^(NSUInteger newSelection, BOOL isFinal, BOOL canceling)
			{
				if(!canceling)
				{
					if(!isIpad && !isFinal)
						return NO;

					NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
					[stdDefaults setObject:[NSNumber numberWithInteger:[ServiceZapListController zapActionForIndex:newSelection]] forKey:kZapModeDefault];
					[stdDefaults synchronize];
					[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
				}
				else if(!isIpad)
					[self.navigationController popToViewController:self animated:YES];

				if(isIpad)
					[self dismissModalViewControllerAnimated:YES];
				return YES;
			};

			if(isIpad)
			{
				targetViewController = [[UINavigationController alloc] initWithRootViewController:vc];
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
			}
			else
				targetViewController = vc;
		}
#if IS_FULL()
		else if(cell.tag == kMultiEPGRowTag)
		{
			NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
			NSInteger selection = (([timeInterval integerValue] / 60) / 30) - 1;
			SimpleSingleSelectionListController *vc = [SimpleSingleSelectionListController withItems:
													   [NSArray arrayWithObjects:[NSString stringWithFormat:NSLocalizedString(@"%d min", @"Minutes"), 30],
														[NSString stringWithFormat:NSLocalizedString(@"%d min", @"Minutes"), 60],
														[NSString stringWithFormat:NSLocalizedString(@"%d min", @"Minutes"), 90],
														[NSString stringWithFormat:NSLocalizedString(@"%d min", @"Minutes"), 120], nil]
																						andSelection:selection
																							andTitle:NSLocalizedString(@"Multi-EPG Interval", @"Default title of MultiEPGIntervalViewController")];
			vc.callback = ^(NSUInteger newSelection, BOOL isFinal, BOOL canceling)
			{
				if(!canceling)
				{
					if(!isIpad && !isFinal)
						return NO;

					NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
					[stdDefaults setObject:[NSNumber numberWithInteger:(newSelection + 1) * 30 * 60] forKey:kMultiEPGInterval];
					[stdDefaults synchronize];
					[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
				}
				else if(!isIpad)
					[self.navigationController popToViewController:self animated:YES];

				if(isIpad)
					[self dismissModalViewControllerAnimated:YES];
				return YES;
			};

			if(isIpad)
			{
				targetViewController = [[UINavigationController alloc] initWithRootViewController:vc];
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
				targetViewController.modalPresentationStyle = vc.modalPresentationStyle;
			}
			else
				targetViewController = vc;
		}
#endif
		if(targetViewController)
		{
			if(isIpad)
				[self presentModalViewController:targetViewController animated:YES];
			else
				[self.navigationController pushViewController:targetViewController animated:YES];
		}

		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else if(indexPath.section == purchaseSection)
	{
		[self performSelectorOnMainThread:@selector(purchaseSectionSelectedAtIndexPath:) withObject:indexPath waitUntilDone:YES];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* indent when editing? */
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Only indent section 0
	return (indexPath.section == connectionSection);
}

/* cell for section */
- (UITableViewCell *)obtainTableCellForIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;

	switch(indexPath.section)
	{
		case purchaseSection:
		case buttonSection:
		case connectionSection:
			cell = [BaseTableViewCell reusableTableViewCellInView:_tableView withIdentifier:kBaseCell_ID];
			break;
		case settingsSection:
			cell = [DisplayCell reusableTableViewCellInView:_tableView withIdentifier:kDisplayCell_ID];
			((DisplayCell *)cell).nameLabel.adjustsFontSizeToFitWidth = NO;
			break;
		default:
			break;
	}

	return cell;
}

/* determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	NSString *hostTitle = nil;
	UITableViewCell *sourceCell = [self obtainTableCellForIndexPath:indexPath];

	// we are creating a new cell, setup its attributes
	switch(section)
	{
		/* Connections */
		case connectionSection:
			
			sourceCell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
			sourceCell.textLabel.font = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
			sourceCell.textLabel.textAlignment = UITextAlignmentLeft;

			/*!
			 @brief When editing we add a fake first item to the list so cover this here.
			 */
			if(self.editing)
			{
				// Setup fake item and abort
				if(row == 0)
				{
					sourceCell.textLabel.text = NSLocalizedString(@"New Connection", @"");
					break;
				}

				// Fix index in list
				row--;
			}

			// set accessory
			if([RemoteConnectorObject getConnectedId] == row)
				sourceCell.accessoryType = UITableViewCellAccessoryCheckmark;
			else
				sourceCell.accessoryType = UITableViewCellAccessoryNone;

			// Title handling
			hostTitle = [(NSDictionary *)[_connections objectAtIndex: row] objectForKey: kRemoteName];
			if(![hostTitle length])
				hostTitle = [(NSDictionary *)[_connections objectAtIndex: row] objectForKey: kRemoteHost];
			sourceCell.textLabel.text = hostTitle;

			break;

		/* Misc configuration items */
		case settingsSection:
			sourceCell.tag = 0;
			if(row >= vibrationRow && IS_IPAD())
				++row;
			if(row >= zapModeRow && ![ServiceZapListController streamPlayerInstalled])
				++row;

			switch(row)
			{
				/* Simple remote */
				case simpleRemoteRow:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Simple Remote", @"");
					((DisplayCell *)sourceCell).view = _simpleRemote;
					break;
				/* Separate events by day */
				case separateEventsRow:
					((DisplayCell *)sourceCell).nameLabel.adjustsFontSizeToFitWidth = YES;
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Separate events by day", @"Toggle to enable sections in event lists");
					((DisplayCell *)sourceCell).view = _sepEventsByDay;
					break;
				/* Vibration */
				case vibrationRow:
					if(!IS_IPAD())
					{
						((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Vibrate in RC", @"");
						((DisplayCell *)sourceCell).view = _vibrateInRC;
					}
					break;
				/* Theme */
				case themeRow:
				{
					DreamoteConfiguration *singleton = [DreamoteConfiguration singleton];
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
					label.backgroundColor = [UIColor clearColor];
					label.font = [UIFont systemFontOfSize:kTextViewFontSize];
					label.textAlignment = UITextAlignmentRight;
					label.text = [[singleton themeNames] objectAtIndex:singleton.currentTheme];
					label.textColor = singleton.textColor;
					label.highlightedTextColor = singleton.highlightedTextColor;
					label.frame = CGRectMake(0, 0, [label sizeThatFits:label.bounds.size].width, kSwitchButtonHeight);
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Theme", @"Configuration item to choose theme");
					((DisplayCell *)sourceCell).view = label;
					sourceCell.tag = kThemeRowTag;
					break;
				}
				/* Default Zap Mode */
				case zapModeRow:
				{
					UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
					label.backgroundColor = [UIColor clearColor];
					label.font = [UIFont systemFontOfSize:kTextViewFontSize];
					label.textAlignment = UITextAlignmentRight;
					label.text = [ServiceZapListController playerName:[[NSUserDefaults standardUserDefaults] integerForKey:kZapModeDefault]];
					label.textColor = [DreamoteConfiguration singleton].textColor;
					label.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
					label.frame = CGRectMake(0, 0, [label sizeThatFits:label.bounds.size].width, kSwitchButtonHeight);;
					sourceCell.textLabel.text = NSLocalizedString(@"Default Zap-Type", @"Label of cell in config which gives default zap type");
					((DisplayCell *)sourceCell).view = label;
					sourceCell.tag = kZapModeRowTag;
					break;
				}
				/* Timeout */
				case timeoutRow:
				{
					UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
					timeLabel.backgroundColor = [UIColor clearColor];
					timeLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					timeLabel.textAlignment = UITextAlignmentRight;
					timeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d sec", @"Seconds"), kTimeout];
					timeLabel.textColor = [DreamoteConfiguration singleton].textColor;
					timeLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
					timeLabel.frame = CGRectMake(0, 0, [timeLabel sizeThatFits:timeLabel.bounds.size].width, kSwitchButtonHeight);;
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Connection Timeout", @"Configuration item to choose connection timeout");
					((DisplayCell *)sourceCell).view = timeLabel;
					sourceCell.tag = kTimeoutRowTag;
					break;
				}
				/* Search History Length */
				case historyLengthRow:
				{
					UILabel *lengthLabel = [[UILabel alloc] initWithFrame:CGRectZero];
					lengthLabel.backgroundColor = [UIColor clearColor];
					lengthLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					lengthLabel.textAlignment = UITextAlignmentRight;
					lengthLabel.text = [NSString stringWithFormat:@"%d", [[NSUserDefaults standardUserDefaults] integerForKey:kSearchHistoryLength]];
					lengthLabel.textColor = [DreamoteConfiguration singleton].textColor;
					lengthLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
					lengthLabel.frame = CGRectMake(0, 0, [lengthLabel sizeThatFits:lengthLabel.bounds.size].width, kSwitchButtonHeight);;
					sourceCell.textLabel.text = NSLocalizedString(@"Search History Length", @"Label of cell in config which gives search history length");
					((DisplayCell *)sourceCell).view = lengthLabel;
					sourceCell.tag = kHistoryLengthRowTag;
					break;
				}
                case customActionRow:
                {
                    sourceCell = [CellTextField reusableTableViewCellInView:tableView withIdentifier:kCellTextField_ID];
                    ((CellTextField *)sourceCell).view = _customActionTextField;
                    break;
                }
#if IS_FULL()
				/* Multi-EPG interval */
				case multiEpgRow:
				{
					NSNumber *timeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:kMultiEPGInterval];
					UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
					timeLabel.backgroundColor = [UIColor clearColor];
					timeLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					timeLabel.textAlignment = UITextAlignmentRight;
					timeLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d min", @"Minutes"), [timeInterval integerValue] / 60];
					timeLabel.textColor = [DreamoteConfiguration singleton].textColor;
					timeLabel.highlightedTextColor = [DreamoteConfiguration singleton].highlightedTextColor;
					timeLabel.frame = CGRectMake(0, 0, [timeLabel sizeThatFits:timeLabel.bounds.size].width, kSwitchButtonHeight);;
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Multi-EPG Interval", @"Configuration item to choose timespan displayed by MultiEPG");
					((DisplayCell *)sourceCell).view = timeLabel;
					sourceCell.tag = kMultiEPGRowTag;
					break;
				}
#endif
				default:
					break;
			}
			break;
		case buttonSection:
		{
			sourceCell.accessoryType = UITableViewCellAccessoryNone;
			sourceCell.textLabel.font = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
			sourceCell.textLabel.textAlignment = UITextAlignmentCenter;
			switch(row)
			{
				case 0:
					sourceCell.textLabel.text = NSLocalizedString(@"Show Help", @"show welcome screen (help)");
					break;
				case 1:
					sourceCell.textLabel.text = NSLocalizedString(@"Search Connections", @"Start AutoConfiguration from ConfigListController");
					break;
#if IS_LITE()
				case 2:
					sourceCell.textLabel.text = NSLocalizedString(@"Export to dreaMote", @"export data from lite to full version");
					break;
#endif
				default: break;
			}
			break;
		}
		case purchaseSection:
		{
			sourceCell.textLabel.font = [UIFont boldSystemFontOfSize:kTextViewFontSize-1];
			sourceCell.textLabel.textAlignment = UITextAlignmentCenter;
			sourceCell.textLabel.adjustsFontSizeToFitWidth = YES;
			NSUInteger count = purchasables.count;
			if((NSUInteger)indexPath.row < count)
			{
				SSKProduct *product = [purchasables objectAtIndex:indexPath.row];
				sourceCell.accessoryType = [SSKManager isFeaturePurchased:product.productIdentifier] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				sourceCell.textLabel.text = [product stringValue];
			}
#if IS_DEBUG()
			else if((NSUInteger)indexPath.row == count + 1)
			{
				sourceCell.accessoryType = UITableViewCellAccessoryNone;
				sourceCell.textLabel.text = NSLocalizedString(@"Forget Purchases", @"Forget previous purchases in config list (debug builds only)");
			}
#endif
			else
			{
				sourceCell.accessoryType = UITableViewCellAccessoryNone;
				sourceCell.textLabel.text = NSLocalizedString(@"Restore Purchases", @"Restore previous purchases in config list");
			}
		}
		default:
			break;
	}

	[[DreamoteConfiguration singleton] styleTableViewCell:sourceCell inTableView:tableView];
	return sourceCell;
}

/* number of section */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger sections = purchaseSection;
	if([SKPaymentQueue canMakePayments] && purchasables.count)
		++sections;
	return sections;
}

/* number of rows in given section */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case connectionSection:
			if(self.editing)
				return [_connections count] + 1;
			return [_connections count];
		case settingsSection:
		{
			NSInteger baseCount = settingsRowMax;
			if(IS_IPAD())
				--baseCount;
			if(![ServiceZapListController streamPlayerInstalled])
				--baseCount;
#if IS_LITE()
			--baseCount;
#endif
			return baseCount;
		}
		case buttonSection:
#if IS_FULL()
			return 2;
#else
			return ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"dreaMote://"]]) ? 3 : 2;
#endif
		case purchaseSection:
		{
			NSUInteger count = purchasables.count;
			if(count)
#if IS_DEBUG()
				count += 2;
#else
				++count;
#endif
			return count;
		}
		default:
			return 0;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if(section == connectionSection || section == purchaseSection)
		return [[DreamoteConfiguration singleton] tableView:tableView heightForHeaderInSection:section];
	return 0.0001;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if(section == connectionSection || section == purchaseSection)
		return [[DreamoteConfiguration singleton] tableView:tableView viewForHeaderInSection:section];
	return 0;
}

/* section header */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		default:
			return nil;
		case connectionSection:
			return NSLocalizedString(@"Configured Connections", @"Section title for connections in ConfigList");
		case purchaseSection:
			return NSLocalizedString(@"Purchase", @"Section title for In-App-Purchases in ConfigList");
	}
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Only custom style in section 0
	if(indexPath.section != connectionSection)
		return UITableViewCellEditingStyleNone;

	// First row is fake "new connection" item
	if(indexPath.row == 0)
		return UITableViewCellEditingStyleInsert;
	return UITableViewCellEditingStyleDelete;
}

/* edit action */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// If row is deleted, remove it from the list.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
		NSInteger currentDefault = [stdDefaults integerForKey: kActiveConnection];
		NSInteger currentConnected = [RemoteConnectorObject getConnectedId];
		NSInteger index = indexPath.row;
		if(self.editing) --index;

		// Shift index
		if(currentDefault > index)
			[stdDefaults setObject: [NSNumber numberWithInteger: currentDefault - 1] forKey: kActiveConnection];
		// Default to 0 if current default connection removed
		else if(currentDefault == index)
		{
			[stdDefaults setObject: [NSNumber numberWithInteger: 0] forKey: kActiveConnection];
			[RemoteConnectorObject disconnect];
			[tableView reloadData];
		}
		// connected is removed
		if(currentConnected == index && currentConnected != currentDefault)
		{
			[RemoteConnectorObject disconnect];
			[tableView reloadData];
		}

		// Remove item
		[_connections removeObjectAtIndex: index];
		[tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: indexPath]
						 withRowAnimation: UITableViewRowAnimationFade];

		// post notification
		[[NSNotificationCenter defaultCenter] postNotificationName:kReconnectNotification object:self userInfo:nil];
	}
	// Add new connection
	else if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
		UIViewController *targetViewController = [ConfigViewController newConnection];
		[self.navigationController pushViewController: targetViewController animated: YES];
	}
}

#pragma mark - UIViewController delegate methods

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
	[_tableView reloadData];
	[_tableView selectRowAtIndexPath:tableSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
	[_tableView deselectRowAtIndexPath:tableSelection animated:YES];

	// start bonjour search
	[RemoteConnectorObject start];
}

/* did hide */
- (void)viewDidDisappear:(BOOL)animated
{
	// in case we changed something, sometimes changes got lost
	[[NSUserDefaults standardUserDefaults] synchronize];

	// unset editing if not going into a subview
	if(self.editing && [_tableView indexPathForSelectedRow] == nil)
		[self setEditing:NO animated:animated];

	// end bonjour search
	[RemoteConnectorObject stop];
}

#pragma mark - ConnectionListDelegate methods

- (void)connectionSelected:(NSMutableDictionary *)dictionary
{
	UIViewController *tvc = [ConfigViewController withConnection:dictionary :-1];
	[self.navigationController pushViewController:tvc animated:YES];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate
#pragma mark -

- (void)hudWasHidden:(MBProgressHUD *)hud
{
	self.navigationItem.rightBarButtonItem.enabled = YES;
	[progressHUD removeFromSuperview];
	self.progressHUD = nil;
}

#pragma mark AutoConfiguration

- (void)doAutoConfiguration
{
	@autoreleasepool {

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
			}
			else
			{
				[self.navigationController pushViewController:tv animated:YES];
			}
		}

	}
}

@end
