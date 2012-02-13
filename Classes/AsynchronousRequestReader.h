//
//  AsynchronousRequestReader.h
//  dreaMote
//
//  Created by Moritz Venn on 13.02.12.
//  Copyright (c) 2012 Moritz Venn. All rights reserved.
//

#import "SynchronousRequestReader.h"

typedef void (^asynchronousRequestReaderDataReceived_t)(NSData *data);
typedef void (^asynchronousRequestReaderError_t)(NSError *error);
typedef void (^asynchronousRequestReaderFinished_t)();

@interface AsynchronousRequestReader : SynchronousRequestReader

@property (nonatomic, copy) asynchronousRequestReaderDataReceived_t dataReceivedBlock;
@property (nonatomic, copy) asynchronousRequestReaderError_t errorBlock;
@property (nonatomic, copy) asynchronousRequestReaderFinished_t finishedBlock;

@end
