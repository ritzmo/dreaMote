//
//  AboutDreamoteViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 18.10.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "AboutDreamoteViewController.h"
#import "Constants.h"

@implementation AboutDreamoteViewController

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"About", @"Title of AboutDreamoteViewController");
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
	UIWebView *aboutText = [[UIWebView alloc] initWithFrame: [[UIScreen mainScreen] applicationFrame]];
	[aboutText loadHTMLString: [NSString stringWithContentsOfFile: [[[NSBundle mainBundle] bundlePath] stringByAppendingString: @"/about.html"] usedEncoding: nil error: nil] baseURL: [NSURL URLWithString: @""]];
	aboutText.backgroundColor = [UIColor clearColor];
	aboutText.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	aboutText.opaque = NO;
	aboutText.delegate = self;

	if(IS_IPAD())
	{
		aboutText.backgroundColor = [UIColor colorWithRed:0.821f green:0.834f blue:0.860f alpha:1];
	}
	else
	{
		aboutText.backgroundColor = [UIColor groupTableViewBackgroundColor];	// use the table view background color
	}

	self.view = aboutText;
	[aboutText release];
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
