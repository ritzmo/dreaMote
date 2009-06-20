//
//  RCButton.h
//  dreaMote
//
//  Created by Moritz Venn on 23.07.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Simple UIButton used to store RC Codes.
 */
@interface RCButton : UIButton {
@public
	NSInteger rcCode; /*!< @brief Assigned RC Code. */
}

/*!
 @brief Rc Code.
 */
@property (nonatomic) NSInteger rcCode;

@end
