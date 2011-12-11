//
//  BaseXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "BaseXMLReader.h"

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
	#import "AppDelegate.h"
#endif

#import "SynchronousRequestReader.h"
#import "Constants.h"

@implementation BaseXMLReader

@synthesize encoding;
@synthesize delegate = _delegate;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		_done = NO;
		_timeout = kTimeout;
		encoding = NSUTF8StringEncoding;
	}
	return self;
}

/* download and parse xml document */
- (void)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error
{
	// NOTE: descending classes should implement this
}

- (void)errorLoadingDocument:(NSError *)error
{
	// delegate wants to be informated about errors
	SEL errorParsing = @selector(dataSourceDelegate:errorParsingDocument:);
	NSMethodSignature *sig = [_delegate methodSignatureForSelector:errorParsing];
	if(_delegate && [_delegate respondsToSelector:errorParsing] && sig)
	{
		BaseXMLReader *__unsafe_unretained dataSource = self;
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:_delegate];
		[invocation setSelector:errorParsing];
		[invocation setArgument:&dataSource atIndex:2];
		[invocation setArgument:&error atIndex:3];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

- (void)finishedParsingDocument
{
	// delegate wants to be informated about parsing end
	SEL finishedParsing = @selector(dataSourceDelegateFinishedParsingDocument:);
	NSMethodSignature *sig = [_delegate methodSignatureForSelector:finishedParsing];
	if(_delegate && [_delegate respondsToSelector:finishedParsing] && sig)
	{
		BaseXMLReader *__unsafe_unretained dataSource = self;
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:_delegate];
		[invocation setSelector:finishedParsing];
		[invocation setArgument:&dataSource atIndex:2];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

@end
