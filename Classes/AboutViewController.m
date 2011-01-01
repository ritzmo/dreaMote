//
//  AboutViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 18.10.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "AboutViewController.h"
#import "Constants.h"

@interface AboutViewController()
/*!
 @brief "done" button was pressed
 @param sender ui element
 */
- (void)buttonPressed: (id)sender;
@end

@implementation AboutViewController

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"About", @"Title of AboutViewController");
	}

	return self;
}

/* dealloc */
- (void)dealloc
{
	[_doneButton release];
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

	frame = CGRectMake(0, 0, size.width, 360);
	UIWebView *aboutText = [[UIWebView alloc] initWithFrame: frame];
	[aboutText loadHTMLString: [NSString stringWithContentsOfFile: [[[NSBundle mainBundle] bundlePath] stringByAppendingString: @"/about.html"] usedEncoding: nil error: nil] baseURL: [NSURL URLWithString: @""]];
	aboutText.backgroundColor = [UIColor clearColor];
	aboutText.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
	aboutText.opaque = NO;
	aboutText.delegate = self;
	[self.view addSubview: aboutText];
	[aboutText release];

	frame = CGRectMake(((size.width - 100) / 2), 360 + kTweenMargin, 100, 34);
	_doneButton = [[UIButton buttonWithType: UIButtonTypeRoundedRect] retain];
	_doneButton.frame = frame;
	[_doneButton setTitle:NSLocalizedString(@"Done", @"") forState: UIControlStateNormal];
	[_doneButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: _doneButton];
}

/* "done" button pressed */
- (void)buttonPressed: (id)sender
{
	[self.parentViewController dismissModalViewControllerAnimated: YES];
}

/* rotate to portrait orientation only */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// allow all orientations on ipad
	if(IS_IPAD())
		return YES;

	// accept any portrait orientation
	return (interfaceOrientation == UIInterfaceOrientationPortrait)
		|| (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
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

	// Auto release
	[requestURL release];

	// If request url is something other than http or https it will open in UIWebView
	// You could also check for the other following protocols: tel, mailto and sms
	return YES;
}

@end
