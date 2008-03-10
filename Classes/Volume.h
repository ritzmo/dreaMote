//
//  Volume.h
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XMLModelObject.h"

@interface Volume : NSObject <XMLModelObject> {

@private
    NSMutableDictionary *_rawAttributes; // Content from the XML parse.
    
    NSString *_result;
    NSString *_resulttext;
	NSString *_current;
	NSString *_ismuted;
}

@property (nonatomic, retain) NSMutableDictionary *rawAttributes;
@property (nonatomic, retain) NSString *result;
@property (nonatomic, retain) NSString *resulttext;
@property (nonatomic, retain) NSString *current;
@property (nonatomic, retain) NSString *ismuted;

@end
