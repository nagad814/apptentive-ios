//
//  ApptentiveGCDDispatchQueue.m
//  Apptentive
//
//  Created by Alex Lementuev on 12/4/17.
//  Copyright © 2017 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveGCDDispatchQueue.h"

#import "ApptentiveDefines.h"

@interface ApptentiveGCDDispatchQueue ()

@property (nonatomic, readonly) NSOperationQueue *queue;
@property (nonatomic, readonly, nullable) NSString *name;

@end

@implementation ApptentiveGCDDispatchQueue

- (instancetype)initWithQueue:(NSOperationQueue *)queue {
	APPTENTIVE_CHECK_INIT_NOT_NIL_ARG(queue);
	self = [super init];
	if (self) {
		_queue = queue;
	}
	return self;
}

- (void)dispatchAsync:(void (^)(void))task {
	ApptentiveAssertNotNil(task, @"Attemped to dispatch nil task on '%@' queue", self.name);
	if (task != nil) {
		[_queue addOperationWithBlock:^{
			[self dispatchTaskGuarded:task];
		}];
	}
}

- (void)dispatchTaskGuarded:(void (^)(void))task {
	@try {
		task();
	} @catch (NSException *exception) {
		ApptentiveLogCrit(@"Exception while dispatching task: %@", exception);
	}
}

#pragma mark -
#pragma mark Properties

#pragma mark -
#pragma mark Properties

- (BOOL)isSuspended {
	return _queue.isSuspended;
}

- (void)setSuspended:(BOOL)suspended {
	_queue.suspended = suspended;
}

- (NSString *)name {
	return _queue.name;
}

@end
