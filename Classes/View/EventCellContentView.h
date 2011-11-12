//
//  EventCellContentView.h
//  dreaMote
//
//  Created by Moritz Venn on 12.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Objects/EventProtocol.h>

@interface EventCellContentView : UIView

/*!
 @brief Event.
 */
@property (nonatomic, strong) NSObject<EventProtocol> *event;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, strong) NSDateFormatter *formatter;

/*!
 @brief Display service name?
 
 @note This needs to be set before assigning a new event to work properly.
 Also the Events needs to keep a copy of the service.
 */
@property (nonatomic, assign) BOOL showService;

@property (nonatomic, getter=isHighlighted) BOOL highlighted;

@end
