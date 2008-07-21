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
	
	BOOL _result;
	NSString *_resulttext;
	int _current;
	BOOL _ismuted;
}

@property (nonatomic, retain) NSMutableDictionary *rawAttributes;
@property (assign) BOOL result;
@property (nonatomic, retain) NSString *resulttext;
@property (assign) int current;
@property (assign) BOOL ismuted;

@end
