//
//  Apptentive+Debugging.m
//  Apptentive
//
//  Created by Frank Schmitt on 1/4/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "Apptentive+Debugging.h"
#import "ApptentiveBackend.h"
#import "ApptentiveBackend+Engagement.h"
#import "ApptentiveInteraction.h"
#import "ApptentiveMessageCenterViewController.h"
#import "ApptentiveDevice.h"
#import "ApptentivePerson.h"
#import "ApptentiveSDK.h"
#import "ApptentiveVersion.h"
#import "ApptentiveEngagementManifest.h"


@implementation Apptentive (Debugging)

- (ApptentiveDebuggingOptions)debuggingOptions {
	return 0;
}

- (NSString *)SDKVersion {
	return self.backend.session.SDK.version.versionString;
}

- (void)setLocalInteractionsURL:(NSURL *)localInteractionsURL {
	self.backend.localEngagementManifestURL = localInteractionsURL;
}

- (NSURL *)localInteractionsURL {
	return self.backend.localEngagementManifestURL;
}

- (NSString *)storagePath {
	return self.backend.supportDirectoryPath;
}

- (UIView *)unreadAccessoryView {
	return [self unreadMessageCountAccessoryView:YES];
}

- (NSString *)manifestJSON {
	NSDictionary *JSONDictionary = self.backend.manifest.JSONDictionary;

	if (JSONDictionary != nil) {
		NSData *outputJSONData = [NSJSONSerialization dataWithJSONObject:JSONDictionary options:NSJSONWritingPrettyPrinted error:NULL];

		return [[NSString alloc] initWithData:outputJSONData encoding:NSUTF8StringEncoding];
	} else {
		return nil;
	}
}

- (NSDictionary *)deviceInfo {
	return Apptentive.shared.backend.session.device.JSONDictionary;
}

- (NSArray *)engagementEvents {
	NSDictionary *targets = Apptentive.shared.backend.manifest.targets;
	NSArray *localCodePoints = [targets.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[c] %@", @"local#app#"]];
	NSMutableArray *eventNames = [NSMutableArray array];
	for (NSString *codePoint in localCodePoints) {
		[eventNames addObject:[codePoint substringFromIndex:10]];
	}

	return eventNames;
}

- (NSArray *)engagementInteractions {
	return self.backend.manifest.interactions.allValues;
}

- (NSInteger)numberOfEngagementInteractions {
	return [[self engagementInteractions] count];
}

- (NSString *)engagementInteractionNameAtIndex:(NSInteger)index {
	ApptentiveInteraction *interaction = [[self engagementInteractions] objectAtIndex:index];

	return [interaction.configuration objectForKey:@"name"] ?: [interaction.configuration objectForKey:@"title"] ?: @"Untitled Interaction";
}

- (NSString *)engagementInteractionTypeAtIndex:(NSInteger)index {
	ApptentiveInteraction *interaction = [[self engagementInteractions] objectAtIndex:index];

	return interaction.type;
}

- (void)presentInteractionAtIndex:(NSInteger)index fromViewController:(UIViewController *)viewController {
	[self.backend presentInteraction:[self.engagementInteractions objectAtIndex:index] fromViewController:viewController];
}

- (void)presentInteractionWithJSON:(NSDictionary *)JSON fromViewController:(UIViewController *)viewController {
	[self.backend presentInteraction:[ApptentiveInteraction interactionWithJSONDictionary:JSON] fromViewController:viewController];
}

- (NSString *)conversationToken {
	return Apptentive.shared.backend.session.token;
}

- (void)resetSDK {
	[self.backend resetBackend];

	[self setValue:nil forKey:@"backend"];
}

- (NSDictionary *)customPersonData {
	return self.backend.session.person.customData ?: @{};
}

- (NSDictionary *)customDeviceData {
	return self.backend.session.device.customData ?: @{};
}

@end