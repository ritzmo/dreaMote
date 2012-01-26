//
//  Volume.h
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Objects/Generic/Result.h>

/*!
 @brief Generic Volume.
 */
@interface GenericVolume : Result

/*!
 @brief Current audio level.
 */
@property (assign) NSInteger current;

/*!
 @brief Audio currently muted?
 */
@property (assign) BOOL ismuted;

@end
