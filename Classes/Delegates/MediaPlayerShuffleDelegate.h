//
//  MediaPlayerShuffleDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 11.04.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief MediaPlayerShuffleDelegate

 Protocol used to manage old school PlayList shuffling.
 */
@protocol MediaPlayerShuffleDelegate

/*!
 @brief Done shuffling.
 */
- (void)finishedShuffling;

/*!
 @brief Inform delegate about number of remaining actions.
 @note "remove track" and subsequent "add track" are one action each.
 */
- (void)remainingShuffleActions:(NSNumber *)count;
@end
