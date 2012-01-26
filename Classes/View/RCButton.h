//
//  RCButton.h
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Simple UIButton used to store RC Codes.
 
 Objects of this type are used in the emulated remote control (see RCEmulatorController)
 and helps settings those up by allowing to assign a normal button a rcCode which will be
 handed to the RemoteConnector which on its side will convert it to a native rc code
 of the STB.
 */
@interface RCButton : UIButton

/*!
 @brief Set the background image for this button.
 Uses an explicit method to set the background image by filename
 so we have it internally for the accessibility texts.
 @param filename Name of the file to be used as background.
 */
- (void)setBackgroundFromFilename:(NSString *)filename;

/*!
 @brief Rc Code.
 */
@property (nonatomic) NSInteger rcCode;

@end
