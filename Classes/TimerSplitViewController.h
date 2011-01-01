//
//  TimerSplitViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.10.
//  Copyright 2010-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IntelligentSplitViewController/IntelligentSplitViewController.h"
#import "TimerListController.h"
#import "TimerViewController.h"

@interface TimerSplitViewController : IntelligentSplitViewController {
@private
	TimerListController *_timerListController;
	TimerViewController *_timerViewController;
}

@end
