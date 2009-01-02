//
//  ControlViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ControlViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
@private
	UISwitch *_switchControl;
	UISlider *_slider;
}

@property (nonatomic, retain) UISwitch *switchControl;
@property (nonatomic, retain) UISlider *slider;

@end
