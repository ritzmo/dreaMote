//
//  AboutDreamoteViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 18.10.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "AboutDreamoteViewController.h"

#import "Constants.h"

@interface AboutDreamoteViewController()
/*!
 @brief "done" button was pressed
 @param sender ui element
 */
- (void)buttonPressed: (id)sender;
/*!
 @brief _mailButton was pressed
 @param sender ui element
 */
- (void)showMailComposer:(id)sender;
/*!
 @brief "Follow us" button was pressed
 @param sender ui element
 */
- (void)openTwitter:(id)sender;
@end

@implementation AboutDreamoteViewController

@synthesize aboutDelegate;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"About", @"Title of AboutDreamoteViewController");

		if([self respondsToSelector:@selector(modalPresentationStyle)])
			self.modalPresentationStyle = UIModalPresentationFormSheet;

		welcomeType = welcomeTypeNone;
	}

	return self;
}

/* initialize with welcome type */
- (id)initWithWelcomeType:(welcomeTypes)inWelcomeType
{
	if((self = [super init]))
	{
		if([self respondsToSelector:@selector(modalPresentationStyle)])
			self.modalPresentationStyle = UIModalPresentationFormSheet;

		welcomeType = inWelcomeType;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[aboutDelegate release];
	[_aboutText release];
	[_doneButton release];
	[_mailButton release];

	[super dealloc];
}

/* layout */
- (void)loadView
{
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	if(IS_IPAD())
	{
		contentView.backgroundColor = [UIColor colorWithRed:0.821f green:0.834f blue:0.860f alpha:1];
	}
	else
	{
		contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];	// use the table view background color
	}

	// setup our content view so that it auto-rotates along with the UViewController
	contentView.autoresizesSubviews = YES;
	contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = contentView;
	[contentView release];

	CGRect frame;
	const CGSize size = self.view.bounds.size;

	frame = CGRectMake(0, 0, size.width, 400);
	_aboutText = [[UIWebView alloc] initWithFrame: frame];
	NSString *html = nil;
	switch(welcomeType)
	{
		default:
		case welcomeTypeNone:
			html = [NSString stringWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/about.html"] usedEncoding:nil error:nil];
			html = [html stringByReplacingOccurrencesOfString:@"@CFBundleVersion" withString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
			break;
		case welcomeTypeChanges:
		{
			NSString *localeIdentifier = [[NSLocale componentsFromLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]] objectForKey:NSLocaleLanguageCode];
			const NSFileManager *fileManager = [NSFileManager defaultManager];
			NSString *fileName = [NSString stringWithFormat:@"/changes_%@.html", localeIdentifier];
			NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
			NSString *filePath = [bundlePath stringByAppendingString:fileName];
			if([fileManager fileExistsAtPath:filePath])
				html = [NSString stringWithContentsOfFile:filePath usedEncoding:nil error:nil];
			else
				html = [NSString stringWithContentsOfFile:[bundlePath stringByAppendingString:@"/changes_en.html"] usedEncoding:nil error:nil];
			break;
		}
		case welcomeTypeFull:
		{
			NSString *localeIdentifier = [[NSLocale componentsFromLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]] objectForKey:NSLocaleLanguageCode];
			const NSFileManager *fileManager = [NSFileManager defaultManager];
			NSString *fileName = [NSString stringWithFormat:@"/welcome_%@.html", localeIdentifier];
			NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
			NSString *filePath = [bundlePath stringByAppendingString:fileName];
			if([fileManager fileExistsAtPath:filePath])
				html = [NSString stringWithContentsOfFile:filePath usedEncoding:nil error:nil];
			else
				html = [NSString stringWithContentsOfFile:[bundlePath stringByAppendingString:@"/welcome_en.html"] usedEncoding:nil error:nil];
			break;
		}
	}
	[_aboutText loadHTMLString:html baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]]];
	_aboutText.backgroundColor = [UIColor clearColor];
	_aboutText.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
	_aboutText.opaque = NO;
	_aboutText.delegate = self;
	[self.view addSubview:_aboutText];

	frame = CGRectMake(((size.width - 100) / 2), 400 + kTweenMargin, 100, 34);
	_doneButton = [[UIButton buttonWithType: UIButtonTypeRoundedRect] retain];
	_doneButton.frame = frame;
	[_doneButton setTitle:NSLocalizedString(@"Done", @"") forState: UIControlStateNormal];
	[_doneButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: _doneButton];

	if(welcomeType == welcomeTypeNone)
	{
		if([MFMailComposeViewController canSendMail])
		{
			frame = CGRectMake(0, 400 + kTweenMargin, 32, 32);
			_mailButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
			_mailButton.frame = frame;
			UIImage *image = [UIImage imageNamed:@"internet-mail.png"];
			[_mailButton setImage:image forState:UIControlStateNormal];
			[_mailButton addTarget:self action:@selector(showMailComposer:) forControlEvents:UIControlEventTouchUpInside];

			[self.view addSubview:_mailButton];
		}

		frame = CGRectMake(size.width - 63, 400 + kTweenMargin, 61, 32);
		_twitterButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		_twitterButton.frame = frame;
		UIImage *image = [UIImage imageNamed:@"twitter-b.png"];
		[_twitterButton setImage:image forState:UIControlStateNormal];
		[_twitterButton addTarget:self action:@selector(openTwitter:) forControlEvents:UIControlEventTouchUpInside];

		[self.view addSubview:_twitterButton];
	}
}

- (void)viewDidUnload
{
	[_aboutText release];
	_aboutText = nil;
	[_doneButton release];
	_doneButton = nil;
	[_mailButton release];
	_mailButton = nil;

	[super viewDidUnload];
}

/* "done" button pressed */
- (void)buttonPressed: (id)sender
{
	[aboutDelegate performSelectorOnMainThread:@selector(dismissedAboutDialog) withObject:nil waitUntilDone:NO];
	[self.parentViewController dismissModalViewControllerAnimated: YES];
}

/* _mailButton was pressed */
- (void)showMailComposer:(id)sender
{
	MFMailComposeViewController *mvc = [[MFMailComposeViewController alloc] init];
	mvc.mailComposeDelegate = [self retain];
	NSString *displayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
	NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	UIDevice *currentDevice = [UIDevice currentDevice];
	[mvc setSubject:[NSString stringWithFormat:@"App Feedback %@", displayName]];
	[mvc setToRecipients:[NSArray arrayWithObject:@"dreamote@ritzmo.de"]];
	NSString *body = [NSString stringWithFormat:@"\n\nDevice: %@\niOS Version: %@\n%@ Version: %@", [currentDevice model], [currentDevice systemVersion], displayName, bundleVersion];
	[mvc setMessageBody:body isHTML:NO];
	if([mvc respondsToSelector:@selector(modalTransitionStyle)])
	{
		mvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	UIViewController *parentViewController = self.parentViewController;
	[parentViewController dismissModalViewControllerAnimated:NO];
	[parentViewController presentModalViewController:mvc animated:YES];
	[mvc release];
}

/* rotate with device on ipad, otherwise to portrait */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if(IS_IPAD())
		return YES;
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

/* view about to appear */
-(void)viewWillAppear:(BOOL)animated
{
	if(IS_IPAD())
	{
		// we have to fix this up on ipad
		const CGSize size = self.view.bounds.size;
		CGRect frame = CGRectMake(0, 0, size.width, size.height - kTweenMargin - 40);
		_aboutText.frame = frame;
		frame = CGRectMake(((size.width - 100) / 2), size.height - kTweenMargin - 34, 100, 34);
		_doneButton.frame = frame;
		frame = CGRectMake(0, size.height - kTweenMargin - 32, 32, 32);
		_mailButton.frame = frame;
		frame = CGRectMake(40, size.height - kTweenMargin - 32, 61, 32);
		_twitterButton.frame = frame;
	}
}

#pragma mark - Twitter

/* taken from http://www.cocoanetics.com/2010/02/making-a-follow-us-on-twitter-button/ */
- (void)openTwitterAppForFollowingUser:(NSString *)twitterUserName
{
	UIApplication *app = [UIApplication sharedApplication];

	// Tweetie: http://developer.atebits.com/tweetie-iphone/protocol-reference/
	NSURL *tweetieURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetie://user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:tweetieURL] && IS_IPHONE()) // custom urls don't work properly on iPad
	{
		[app openURL:tweetieURL];
		return;
	}

	// Birdfeed: http://birdfeed.tumblr.com/post/172994970/url-scheme
	NSURL *birdfeedURL = [NSURL URLWithString:[NSString stringWithFormat:@"x-birdfeed://user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:birdfeedURL])
	{
		[app openURL:birdfeedURL];
		return;
	}

	// Twittelator: http://www.stone.com/Twittelator/Twittelator_API.html
	NSURL *twittelatorURL = [NSURL URLWithString:[NSString stringWithFormat:@"twit:///user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:twittelatorURL])
	{
		[app openURL:twittelatorURL];
		return;
	}

	// Icebird: http://icebirdapp.com/developerdocumentation/
	NSURL *icebirdURL = [NSURL URLWithString:[NSString stringWithFormat:@"icebird://user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:icebirdURL])
	{
		[app openURL:icebirdURL];
		return;
	}

	// Fluttr: no docs
	NSURL *fluttrURL = [NSURL URLWithString:[NSString stringWithFormat:@"fluttr://user/%@", twitterUserName]];
	if ([app canOpenURL:fluttrURL])
	{
		[app openURL:fluttrURL];
		return;
	}

	// SimplyTweet: http://motionobj.com/blog/url-schemes-in-simplytweet-23
	NSURL *simplytweetURL = [NSURL URLWithString:[NSString stringWithFormat:@"simplytweet:?link=http://twitter.com/%@", twitterUserName]];
	if ([app canOpenURL:simplytweetURL])
	{
		[app openURL:simplytweetURL];
		return;
	}

	// Tweetings: http://tweetings.net/iphone/scheme.html
	NSURL *tweetingsURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetings:///user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:tweetingsURL])
	{
		[app openURL:tweetingsURL];
		return;
	}

	// Echofon: http://echofon.com/twitter/iphone/guide.html
	NSURL *echofonURL = [NSURL URLWithString:[NSString stringWithFormat:@"echofon:///user_timeline?%@", twitterUserName]];
	if ([app canOpenURL:echofonURL])
	{
		[app openURL:echofonURL];
		return;
	}

	// --- Fallback: Mobile Twitter in Safari
	NSURL *safariURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://mobile.twitter.com/%@", twitterUserName]];
	[app openURL:safariURL];
}

- (void)openTwitter:(id)sender
{
	[self openTwitterAppForFollowingUser:@"dreaMote"];
}

#pragma mark - UIWebView delegates

/* load url? */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	const NSURL *requestURL = [[request URL] retain];

	// Check to see what protocol/scheme the requested URL is.
	if ( ([requestURL.scheme isEqualToString: @"http"]
		  || [requestURL.scheme isEqualToString: @"https"])
		&& (navigationType == UIWebViewNavigationTypeLinkClicked) )
	{
		return ![[UIApplication sharedApplication] openURL: [requestURL autorelease]];
	}
	else if( [requestURL.scheme isEqualToString:@"mailto"]
		&& (navigationType == UIWebViewNavigationTypeLinkClicked) )
	{
		[self showMailComposer:nil];
		[requestURL release];
		return NO;
	}
	[requestURL release];

	// If request url is something other than http or https it will open in UIWebView
	// You could also check for the other following protocols: tel, mailto and sms
	return YES;
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	if(result == MFMailComposeResultFailed)
	{
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error sending email!", @"Title of alert when sending/saving of email failed")
															  message:[error localizedDescription]
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	[controller.parentViewController dismissModalViewControllerAnimated:YES];
	[controller.mailComposeDelegate release];
	controller.mailComposeDelegate = nil;

	[aboutDelegate performSelectorOnMainThread:@selector(dismissedAboutDialog) withObject:nil waitUntilDone:NO];
}

@end
