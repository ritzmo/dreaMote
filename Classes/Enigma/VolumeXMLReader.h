//
//  VolumeXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Volume.h"
#import "BaseXMLReader.h"

@interface VolumeXMLReader : BaseXMLReader
{
@private
	Volume *_currentVolumeObject;
}

+ (VolumeXMLReader*)initWithTarget:(id)target action:(SEL)action;
//- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;

@property (nonatomic, retain) Volume *currentVolumeObject;

@end
