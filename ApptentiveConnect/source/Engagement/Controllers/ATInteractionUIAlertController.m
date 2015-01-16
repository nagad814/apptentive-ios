//
//  ATInteractionUIAlertController.m
//  ApptentiveConnect
//
//  Created by Peter Kamb on 12/1/14.
//  Copyright (c) 2014 Apptentive, Inc. All rights reserved.
//

#import "ATInteractionUIAlertController.h"
#import "ATEngagementBackend.h"
#import "ATInteractionInvocation.h"

NSString *const ATInteractionUIAlertControllerEventLabelLaunch = @"launch";
NSString *const ATInteractionUIAlertControllerEventLabelCancel = @"cancel";
NSString *const ATInteractionUIAlertControllerEventLabelDismiss = @"dismiss";
NSString *const ATInteractionUIAlertControllerEventLabelInteraction = @"interaction";

@implementation ATInteractionUIAlertController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)presentAlertControllerFromViewController:(UIViewController *)viewController {
	self.viewController = viewController;
	
	[viewController presentViewController:self animated:YES completion:^{
		[[ATEngagementBackend sharedBackend] engageApptentiveEvent:ATInteractionUIAlertControllerEventLabelLaunch fromInteraction:self.interaction fromViewController:self.viewController];
	}];
}

+ (instancetype)alertControllerWithInteraction:(ATInteraction *)interaction {
	NSDictionary *config = interaction.configuration;
	NSString *title = config[@"title"];
	NSString *message = config[@"body"];
	
	if (!title && !message) {
		ATLogError(@"Cannot show an Apptentive alert without a title or message.");
		return nil;
	}
	
	NSString *layout = config[@"layout"];
	UIAlertControllerStyle preferredStyle;
	if ([layout isEqualToString:@"center"]) {
		preferredStyle = UIAlertControllerStyleAlert;
	} else if ([layout isEqualToString:@"bottom"]) {
		preferredStyle = UIAlertControllerStyleActionSheet;
	} else {
		preferredStyle = UIAlertControllerStyleAlert;
	}
	
	ATInteractionUIAlertController *alertController = [super alertControllerWithTitle:title message:message preferredStyle:preferredStyle];
	alertController.interaction = interaction;
	
	BOOL cancelActionAdded = NO;
	NSArray *actions = config[@"actions"];
	for (NSDictionary *action in actions) {
		UIAlertAction *alertAction = [alertController alertActionWithConfiguration:action];
		
		// Adding more than one cancel action to the alert causes crash.
		// 'NSInternalInconsistencyException', reason: 'UIAlertController can only have one action with a style of UIAlertActionStyleCancel'
		if (alertAction.style == UIAlertActionStyleCancel) {
			if (!cancelActionAdded) {
				cancelActionAdded = YES;
			} else {
				// Additional cancel buttons are ignored.
				break;
			}
		}
		
		[alertController addAction:alertAction];
	}
	
	return alertController;
}

- (UIAlertAction *)alertActionWithConfiguration:(NSDictionary *)configuration {
	NSString *title = configuration[@"label"] ?: @"button";
	
	NSString *styleString = configuration[@"style"];
	UIAlertActionStyle style;
	if ([styleString isEqualToString:@"default"]) {
		style = UIAlertActionStyleDefault;
	} else if ([styleString isEqualToString:@"cancel"]) {
		style = UIAlertActionStyleCancel;
	} else if ([styleString isEqualToString:@"destructive"]) {
		style = UIAlertActionStyleDestructive;
	} else {
		style = UIAlertActionStyleDefault;
	}
	
	NSString *actionType = configuration[@"action"];
	alertActionHandler actionHandler;
	if ([actionType isEqualToString:@"dismiss"]) {
		actionHandler = [self createButtonHandlerBlockDismiss];
	} else if ([actionType isEqualToString:@"interaction"]) {
		NSArray *jsonInvocations = configuration[@"invokes"];
		NSArray *invocations = [ATInteractionInvocation invocationsWithJSONArray:jsonInvocations];
		actionHandler = [self createButtonHandlerBlockWithInvocations:invocations];
	} else {
		actionHandler = [self createButtonHandlerBlockDismiss];
	}
	
	UIAlertAction *alertAction = [UIAlertAction actionWithTitle:title style:style handler:actionHandler];
	Block_release(actionHandler);
	
	BOOL enabled = configuration[@"enabled"] ? [configuration[@"enabled"] boolValue] : YES;
	alertAction.enabled = enabled;
	
	return alertAction;
}

- (alertActionHandler)createButtonHandlerBlockDismiss {
	return Block_copy(^(UIAlertAction *action) {
		[[ATEngagementBackend sharedBackend] engageApptentiveEvent:ATInteractionUIAlertControllerEventLabelDismiss fromInteraction:self.interaction fromViewController:self.viewController];
	});
}

- (alertActionHandler)createButtonHandlerBlockWithInvocations:(NSArray *)invocations {
	return Block_copy(^(UIAlertAction *action) {
		[[ATEngagementBackend sharedBackend] engageApptentiveEvent:ATInteractionUIAlertControllerEventLabelInteraction fromInteraction:self.interaction fromViewController:self.viewController];
		
		ATInteraction *interaction = [[ATEngagementBackend sharedBackend] interactionForInvocations:invocations];
		[[ATEngagementBackend sharedBackend] presentInteraction:interaction fromViewController:self.viewController];
	});
}

@end