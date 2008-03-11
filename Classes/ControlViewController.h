//
//  ControlViewController.h
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Volume.h"

@interface ControlViewController : UIViewController {
@private
	Volume *_volume;
	UISwitch *_switchControl;
	UISlider *_slider;
}

+ (UILabel *)fieldLabelWithFrame:(CGRect)frame title:(NSString *)title;

@property (nonatomic, retain) Volume *volume;
@property (nonatomic, retain) UISwitch *switchControl;
@property (nonatomic, retain) UISlider *slider;

@end
