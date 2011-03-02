//
//  AdSupportedSplitViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#if IS_LITE()
#import "iAd/ADBannerView.h"
#endif

#import "MGSplitViewController/MGSplitViewController.h"

@interface AdSupportedSplitViewController : MGSplitViewController
#if IS_LITE()
											<ADBannerViewDelegate>
#endif
{
@private
#if IS_LITE()
	id _adBannerView;
	BOOL _adBannerViewIsVisible;
	CGFloat _adBannerHeight;
#endif
}

@end
