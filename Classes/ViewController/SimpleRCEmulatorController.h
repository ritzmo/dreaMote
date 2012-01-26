//
//  SimpleRCEmulatorController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.10.09.
//  Copyright 2009-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCEmulatorController.h"

/*!
 @brief Even simpler emulated remote control.
 */
@interface SimpleRCEmulatorController : RCEmulatorController
{
@private
	CGPoint lastLocation; /*!< @brief Last touch location. */

	UIButton *_lameButton; /*!< @brief Lame/Exit Button. */
	UIButton *_menuButton; /*!< @brief Menu Button. */
	UIButton *_swipeArea; /*!< @brief Swipe Area (4-sided-arrow). */
}

@end
