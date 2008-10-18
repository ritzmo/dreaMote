//
//  VolumeXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"

@class Volume;

@interface VolumeXMLReader : BaseXMLReader
{
@private
	Volume *_currentVolumeObject;
}

+ (VolumeXMLReader*)initWithTarget:(id)target action:(SEL)action;

@property (nonatomic, retain) Volume *currentVolumeObject;

@end
