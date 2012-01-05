//
//  AutoTimerSettings.h
//  dreaMote
//
//  Created by Moritz Venn on 02.12.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
	REFRESH_NONE = 0,
	REFRESH_AUTO,
	REFRESH_ALL,
} autotimerRefresh_t;

typedef enum
{
	EDITOR_CLASSIC = 0,
	EdiTOR_WIZARD,
} autotimerEditor_t;

@interface AutoTimerSettings : NSObject

@property (assign) BOOL autopoll;
@property (assign) NSInteger interval;
@property (assign) autotimerRefresh_t refresh;
@property (assign) BOOL try_guessing;
@property (assign) autotimerEditor_t editor;
@property (assign) BOOL addsimilar_on_conflict;
@property (assign) BOOL disabled_on_conflict;
@property (assign) BOOL show_in_extensionsmenu;
@property (assign) BOOL fastscan;
@property (assign) BOOL notifconflict;
@property (assign) BOOL notifsimilar;
@property (assign) NSInteger maxdays;
@property (nonatomic, assign) BOOL hasVps;
@property (assign) NSInteger version;
@property (assign) double api_version;

@end
