//
//  TimerSplitViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BaseSplitViewController.h"
#import "TimerListController.h"
#import "TimerViewController.h"

@interface TimerSplitViewController : BaseSplitViewController {
@private
	TimerListController *_timerListController;
	TimerViewController *_timerViewController;
}

@end
