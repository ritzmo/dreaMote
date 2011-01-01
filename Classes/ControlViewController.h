//
//  ControlViewController.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "VolumeSourceDelegate.h"

/*!
 @brief STB Control.
 
 Control of simple functions like volume, power state and eventually (if RemoteConnector supports
 it) instant record.
 */
@interface ControlViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
													VolumeSourceDelegate>
{
@private
	UISwitch *_switchControl; /*!< @brief Mute switch. */
	UISlider *_slider; /*!< @brief Volume slider. */
}

/*!
 @brief Mute switch.
 */
@property (nonatomic, retain) UISwitch *switchControl;

/*!
 @brief Volume slider.
 */
@property (nonatomic, retain) UISlider *slider;

@end
