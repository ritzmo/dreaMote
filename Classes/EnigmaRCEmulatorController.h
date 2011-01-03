//
//  EnigmaRCEmulatorController.h
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RCEmulatorController.h"

/*!
 @brief Emulated Remote Control for Enigma.
 
 Emulated Remote Control designed for Enigma and Enigma2 with "normal" remote control device.
 */
@interface EnigmaRCEmulatorController : RCEmulatorController
{
@private
	UIView *_keyPad; /*!< @brief View containing Number keys. */
	UIView *_navigationPad; /*!< @brief View containing Navigation keys. */

	CGRect _landscapeFrame; /*!< @brief Frame for rcView in landscape orientation. */
	CGRect _portraitFrame; /*!< @brief Frame for rcView in portrait orientation. */
	CGRect _landscapeNavigationFrame; /*!< @brief Frame for _navigationPad in landscape orientation. */
	CGRect _portraitNavigationFrame; /*!< @brief Frame for _navigationPad in portrait orientation. */
	CGRect _portraitKeyFrame; /*!< @brief Frame of _keyPad in portrait orientation. */
}

@end
