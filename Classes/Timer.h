//
//  Timer.h
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMLModelObject.h"

@interface Timer : NSObject <XMLModelObject> {

@private
    NSMutableDictionary *_rawAttributes; // Content from the XML parse.
    
    NSString *_eit;
    NSString *_begin;
	NSString *_duration;
	NSString *_disabled;
	NSString *_title;
	NSString *_tdescription;
	NSString *_repeated;
	NSString *_justplay;
	// XXX: add service
}

@property (nonatomic, retain) NSMutableDictionary *rawAttributes;
@property (nonatomic, retain) NSString *eit;
@property (nonatomic, retain) NSString *begin;
@property (nonatomic, retain) NSString *duration;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *tdescription;
@property (nonatomic, retain) NSString *disabled;
@property (nonatomic, retain) NSString *repeated;
@property (nonatomic, retain) NSString *justplay;

@end