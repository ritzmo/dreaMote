//
//  ControlViewController.h
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Volume.h"

@interface ControlViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate,
														UITextFieldDelegate, UITableViewDelegate,
														UITableViewDataSource>
{
@private
	UISwitch *_switchControl;
	UISlider *_slider;
	UITableView *myTableView;
}

@property (nonatomic, retain) UISwitch *switchControl;
@property (nonatomic, retain) UISlider *slider;
@property (nonatomic, retain) UITableView *myTableView;

@end
