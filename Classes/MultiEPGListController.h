//
//  MultiEPGListController.h
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ReloadableListController.h"

#import "EPGCache.h"
#import "EventSourceDelegate.h"
#import "ServiceSourceDelegate.h"

// forward declare
@class CXMLDocument;

@interface MultiEPGListController : ReloadableListController <UITableViewDelegate,
															UITableViewDataSource,
															EPGCacheDelegate,
															EventSourceDelegate,
															ServiceSourceDelegate>
{
@private
	EPGCache *_epgCache;
	NSMutableArray *_services;
	CXMLDocument *_serviceXMLDocument;
	NSMutableDictionary *_events;
}

@end
