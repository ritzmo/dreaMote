//
//  SimulatedTimer.h
//  dreaMote
//
//  Created by Moritz Venn on 09.01.12.
//  Copyright (c) 2012 Moritz Venn. All rights reserved.
//

#import <Objects/Generic/Timer.h>

@interface SimulatedTimer : GenericTimer

- (NSComparisonResult)autotimerCompare:(SimulatedTimer *)other;
- (NSComparisonResult)timeCompare:(SimulatedTimer *)other;

/*!
 @brief Name of the associated AutoTimer.
 */
@property (nonatomic, strong) NSString *autotimerName;

@end
