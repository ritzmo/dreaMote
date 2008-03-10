//
//  Event.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMLModelObject.h"

@interface Event : NSObject <XMLModelObject> {

@private
    NSMutableDictionary *_rawAttributes; // Content from the XML parse.
    
    NSString *_eit;
    NSString *_begin;
	NSString *_duration;
	NSString *_title;
	NSString *_sdescription;
	NSString *_edescription;
}

@property (nonatomic, retain) NSMutableDictionary *rawAttributes;
@property (nonatomic, retain) NSString *eit;
@property (nonatomic, retain) NSString *begin;
@property (nonatomic, retain) NSString *duration;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *sdescription;
@property (nonatomic, retain) NSString *edescription;

@end