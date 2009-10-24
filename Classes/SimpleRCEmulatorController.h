//
//  SimpleRCEmulatorController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
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
}

@end
