//
//  TimerSplitViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.10.
//  Copyright 2010-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AdSupportedSplitViewController.h"
#import "TimerListController.h"
#import "TimerViewController.h"

@interface TimerSplitViewController : AdSupportedSplitViewController {
@private
	TimerListController *_timerListController;
	TimerViewController *_timerViewController;
}

@end
