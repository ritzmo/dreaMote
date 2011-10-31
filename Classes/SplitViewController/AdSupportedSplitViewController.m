//
//  AdSupportedSplitViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 02.03.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AdSupportedSplitViewController.h"

@interface AdSupportedSplitViewController()
#if INCLUDE_FEATURE(Ads)
- (void)createAdBannerView;
- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation;
@property (nonatomic, strong) id adBannerView;
@property (nonatomic) BOOL adBannerViewIsVisible;
#endif
@end


@implementation AdSupportedSplitViewController

#if INCLUDE_FEATURE(Ads)
@synthesize adBannerView = _adBannerView;
@synthesize adBannerViewIsVisible = _adBannerViewIsVisible;
#endif

- (void)loadView
{
	[super loadView];

#if INCLUDE_FEATURE(Ads)
	[self createAdBannerView];
#endif
}


- (void)viewDidUnload
{
#if INCLUDE_FEATURE(Ads)
	[_adBannerView setDelegate:nil];
	_adBannerView = nil;
#endif
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
#if INCLUDE_FEATURE(Ads)
	[self fixupAdView:self.interfaceOrientation];
#endif
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
										 duration:(NSTimeInterval)duration
{
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation 
											duration:duration];
#if INCLUDE_FEATURE(Ads)
	[self fixupAdView:toInterfaceOrientation];
#endif
}

#pragma mark ADBannerViewDelegate
#if INCLUDE_FEATURE(Ads)

//#define __BOTTOM_AD__

- (CGFloat)getBannerHeight:(UIInterfaceOrientation)orientation
{
	if(UIInterfaceOrientationIsLandscape(orientation))
		return IS_IPAD() ? 66 : 32;
	else
		return IS_IPAD() ? 66 : 50;
}

- (CGFloat)getBannerHeight
{
	return [self getBannerHeight:self.interfaceOrientation];
}

- (void)createAdBannerView
{
	Class classAdBannerView = NSClassFromString(@"ADBannerView");
	if(classAdBannerView != nil)
	{
		self.adBannerView = [[classAdBannerView alloc] initWithFrame:CGRectZero];
		[_adBannerView setRequiredContentSizeIdentifiers:[NSSet setWithObjects:
														  ADBannerContentSizeIdentifierPortrait,
														  ADBannerContentSizeIdentifierLandscape,
														  nil]];
		if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		{
			[_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
		}
		else
		{
			[_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
		}
#ifdef __BOTTOM_AD__
		// Banner at Bottom
		CGRect cgRect =[[UIScreen mainScreen] bounds];
		CGSize cgSize = cgRect.size;
		[_adBannerView setFrame:CGRectOffset([_adBannerView frame], 0, cgSize.height + [self getBannerHeight])];
#else
		// Banner at the Top
		[_adBannerView setFrame:CGRectOffset([_adBannerView frame], 0, -[self getBannerHeight])];
#endif
		[_adBannerView setDelegate:self];
		
		[self.view addSubview:_adBannerView];
	}
}

// XXX: only supports vertical split
- (void)fixupAdView:(UIInterfaceOrientation)toInterfaceOrientation
{
	if (_adBannerView != nil)
	{
		if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
		{
			[_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierLandscape];
		}
		else
		{
			[_adBannerView setCurrentContentSizeIdentifier:ADBannerContentSizeIdentifierPortrait];
		}
		[UIView beginAnimations:@"fixupViews" context:nil];
		if(_adBannerViewIsVisible)
		{
			CGRect adBannerViewFrame = [_adBannerView frame];
			CGRect masterViewFrame = self.masterViewController.view.frame;
			CGRect detailViewFrame = self.detailViewController.view.frame;
			CGFloat newBannerHeight = [self getBannerHeight:toInterfaceOrientation];

			adBannerViewFrame.origin.x = 0;
#ifdef __BOTTOM_AD__
			CGSize cgSize = [[UIScreen mainScreen] bounds].size;
			adBannerViewFrame.origin.y = cgSize.height - newBannerHeight - self.tabBarController.tabBar.frame.size.height;
#else
			adBannerViewFrame.origin.y = 0;
#endif
			[_adBannerView setFrame:adBannerViewFrame];
			[self.view bringSubviewToFront:_adBannerView];

#ifdef __BOTTOM_AD__
			masterViewFrame.origin.y = 0;
			detailViewFrame.origin.y = 0;
#else
			masterViewFrame.origin.y = newBannerHeight;
			detailViewFrame.origin.y = newBannerHeight;
#endif
			masterViewFrame.size.height = self.view.frame.size.height - newBannerHeight;
			detailViewFrame.size.height = self.view.frame.size.height - newBannerHeight;
			self.masterViewController.view.frame = masterViewFrame;
			self.detailViewController.view.frame = detailViewFrame;
		}
		else
		{
			CGRect adBannerViewFrame = [_adBannerView frame];
			adBannerViewFrame.origin.x = 0;
#ifdef __BOTTOM_AD__
			CGSize cgSize = [[UIScreen mainScreen] bounds].size;
			adBannerViewFrame.origin.y = cgSize.height + [self getBannerHeight:toInterfaceOrientation];
#else
			adBannerViewFrame.origin.y = -[self getBannerHeight:toInterfaceOrientation];
#endif
			[_adBannerView setFrame:adBannerViewFrame];

			CGRect masterViewFrame = self.masterViewController.view.frame;
			CGRect detailViewFrame = self.detailViewController.view.frame;
			masterViewFrame.origin.y = 0;
			detailViewFrame.origin.y = 0;
			masterViewFrame.size.height = self.view.frame.size.height;
			detailViewFrame.size.height = self.view.frame.size.height;
			self.masterViewController.view.frame = masterViewFrame;
			self.detailViewController.view.frame = detailViewFrame;
		}
		[UIView commitAnimations];
	}
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	if(!_adBannerViewIsVisible)
	{
		_adBannerViewIsVisible = YES;
		[self fixupAdView:self.interfaceOrientation];
	}
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	if(_adBannerViewIsVisible)
	{
		_adBannerViewIsVisible = NO;
		[self fixupAdView:self.interfaceOrientation];
	}
}
#endif

@end
