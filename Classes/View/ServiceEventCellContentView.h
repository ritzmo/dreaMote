//
//  ServiceEventCellContentView.h
//  dreaMote
//
//  Created by Moritz Venn on 12.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Objects/EventProtocol.h>

@interface ServiceEventCellContentView : UIView
{
@private
	NSInteger timeWidth; /*!< @brief Width reserved for time. */
	BOOL editing;
	BOOL highlighted;
}

/*!
 @brief Date Formatter.
 */
@property (nonatomic, strong) NSDateFormatter *formatter;

/*!
 @brief Current Event.
 */
@property (nonatomic, strong) NSObject<EventProtocol> *now;

/*!
 @brief Next Event.
 */
@property (nonatomic, strong) NSObject<EventProtocol> *next;

@property (nonatomic, getter=isEditing) BOOL editing;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@end
