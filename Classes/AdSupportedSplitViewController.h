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
#if IS_LITE()
@private
	id _adBannerView;
	BOOL _adBannerViewIsVisible;
#endif
}

@end
