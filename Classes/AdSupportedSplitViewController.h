//
//  AdSupportedSplitViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 02.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#if SHOW_ADS()
#import "iAd/ADBannerView.h"
#endif

#import "MGSplitViewController/MGSplitViewController.h"

@interface AdSupportedSplitViewController : MGSplitViewController
#if SHOW_ADS()
											<ADBannerViewDelegate>
#endif
{
#if SHOW_ADS()
@private
	id _adBannerView;
	BOOL _adBannerViewIsVisible;
#endif
}

@end
