//
//  Timer.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMLModelObject.h"
#import "Service.h"
#import "Event.h"

@interface Timer : NSObject <XMLModelObject> {

@private
    NSMutableDictionary *_rawAttributes; // Content from the XML parse.
    
    NSString *_eit;
	NSDate *_begin;
	NSDate *_end;
	BOOL _disabled;
	NSString *_title;
	NSString *_tdescription;
	int _repeated;
	BOOL _justplay;
	Service *_service;
	NSString *_sref;
	int _state;
}

+ (Timer *)withEvent: (Event *)ourEvent;
+ (Timer *)new;

@property (nonatomic, retain) NSMutableDictionary *rawAttributes;
@property (nonatomic, retain) NSString *eit;
@property (nonatomic, retain) NSDate *begin;
@property (nonatomic, retain) NSDate *end;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *tdescription;
@property (assign) BOOL disabled;
@property (assign) int repeated;
@property (assign) BOOL justplay;
@property (nonatomic, retain) Service *service;
@property (nonatomic, retain) NSString *sref;
@property (assign) int state;

@end