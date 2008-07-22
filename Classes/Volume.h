//
//  Volume.h
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Volume : NSObject
{
@private
	BOOL _result;
	NSString *_resulttext;
	int _current;
	BOOL _ismuted;
}

@property (assign) BOOL result;
@property (nonatomic, retain) NSString *resulttext;
@property (assign) int current;
@property (assign) BOOL ismuted;

@end
