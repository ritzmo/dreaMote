//
//  RCButton.h
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Simple UIButton used to store RC Codes.
 
 Objects of this type are used in the emulated remote control (see RCEmulatorController)
 and helps settings those up by allowing to assign a normal button a rcCode which will be
 handed to the RemoteConnector which on its side will convert it to a native rc code
 of the STB.
 */
@interface RCButton : UIButton {
@public
	IBOutlet NSInteger rcCode; /*!< @brief Assigned RC Code. */
}

/*!
 @brief Rc Code.
 */
@property (nonatomic) IBOutlet NSInteger rcCode;

@end
