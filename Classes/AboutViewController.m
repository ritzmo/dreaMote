//
//  AboutViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 18.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AboutViewController.h"
#import "Constants.h"

@implementation AboutViewController

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"About", @"Title of AboutViewController");
	}

	return self;
}

- (void)dealloc
{
	[doneButton release];
	[super dealloc];
}

- (void)loadView
{
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];	// use the table view background color

	// setup our content view so that it auto-rotates along with the UViewController
	contentView.autoresizesSubviews = YES;
	contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = contentView;
	[contentView release];

	CGRect frame;
	CGSize size = self.view.bounds.size;

	frame = CGRectMake(0.0, 0.0, size.width, kTextViewHeight);
	UIWebView *aboutText = [[UIWebView alloc] initWithFrame: frame];
	[aboutText loadHTMLString: [NSString stringWithContentsOfFile: [[[NSBundle mainBundle] bundlePath] stringByAppendingString: @"/about.html"]] baseURL: [NSURL URLWithString: @""]];
	aboutText.backgroundColor = [UIColor clearColor];
	aboutText.delegate = self;
	[self.view addSubview: aboutText];
	[aboutText release];

	frame = CGRectMake(((size.width - 100.0) / 2), kTextViewHeight + kTweenMargin, 100.0, 34.0);
	doneButton = [[UIButton buttonWithType: UIButtonTypeRoundedRect] retain];
	doneButton.frame = frame;
	[doneButton setTitle:NSLocalizedString(@"Done", @"") forState: UIControlStateNormal];
	[doneButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: doneButton];
}

- (void)buttonPressed: (id)sender
{
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIWebView delegates

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType; {
	NSURL *requestURL = [[request URL] retain];
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
