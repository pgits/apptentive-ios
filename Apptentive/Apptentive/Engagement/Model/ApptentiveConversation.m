//
//  ApptentiveConversation.m
//  Apptentive
//
//  Created by Frank Schmitt on 11/15/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveConversation.h"
#import "ApptentiveAppRelease.h"
#import "ApptentiveSDK.h"
#import "ApptentivePerson.h"
#import "ApptentiveDevice.h"
#import "ApptentiveEngagement.h"
#import "ApptentiveUtilities.h"
#import "ApptentiveVersion.h"
#import "ApptentiveConversationMetadataItem.h"

static NSString *const AppReleaseKey = @"appRelease";
static NSString *const SDKKey = @"SDK";
static NSString *const PersonKey = @"person";
static NSString *const DeviceKey = @"device";
static NSString *const EngagementKey = @"engagement";
static NSString *const APIKeyKey = @"APIKey";
static NSString *const TokenKey = @"token";
static NSString *const LastMessageIDKey = @"lastMessageID";
static NSString *const MutableUserInfoKey = @"mutableUserInfo";
static NSString *const ArchiveVersionKey = @"archiveVersion";
static NSString *const IdentifierKey = @"identifier";
static NSString *const DirectoryNameKey = @"directoryName";
static NSString *const LastSentDeviceKey = @"lastSentDevice";
static NSString *const LastSentPersonKey = @"lastSentPerson";


// Legacy keys
static NSString *const ATCurrentConversationPreferenceKey = @"ATCurrentConversationPreferenceKey";
static NSString *const ATMessageCenterDraftMessageKey = @"ATMessageCenterDraftMessageKey";
static NSString *const ATMessageCenterDidSkipProfileKey = @"ATMessageCenterDidSkipProfileKey";

NSString *NSStringFromApptentiveConversationState(ApptentiveConversationState state) {
	switch (state) {
		case ApptentiveConversationStateUndefined:
			return @"undefined";
		case ApptentiveConversationStateAnonymousPending:
			return @"anonymous pending";
		case ApptentiveConversationStateLegacyPending:
			return @"legacy pending";
		case ApptentiveConversationStateAnonymous:
			return @"anonymous";
		case ApptentiveConversationStateLoggedIn:
			return @"logged-in";
		case ApptentiveConversationStateLoggedOut:
			return @"logged-out";
	}

	return @"unknown";
}


@interface ApptentiveConversation ()

@property (assign, nonatomic) ApptentiveConversationState state;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *legacyToken;
@property (strong, nonatomic) NSString *userId;
@property (strong, nonatomic) NSData *encryptionKey;
@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *lastMessageID;
@property (strong, nonatomic) ApptentiveAppRelease *appRelease;
@property (strong, nonatomic) ApptentiveSDK *SDK;
@property (strong, nonatomic) ApptentivePerson *person;
@property (strong, nonatomic) ApptentiveDevice *device;
@property (strong, nonatomic) ApptentiveEngagement *engagement;
@property (strong, nonatomic) NSMutableDictionary *mutableUserInfo;
@property (strong, nonatomic) NSDictionary *lastSentPerson;
@property (strong, nonatomic) NSDictionary *lastSentDevice;
@property (strong, nonatomic) NSString *directoryName;

@end


@implementation ApptentiveConversation

- (instancetype)initWithState:(ApptentiveConversationState)state {
	self = [super init];
	if (self) {
        _state = state;
		_appRelease = [[ApptentiveAppRelease alloc] initWithCurrentAppRelease];
		_SDK = [[ApptentiveSDK alloc] initWithCurrentSDK];
		_person = [[ApptentivePerson alloc] init];
		_device = [[ApptentiveDevice alloc] initWithCurrentDevice];
		_engagement = [[ApptentiveEngagement alloc] init];
		_mutableUserInfo = [[NSMutableDictionary alloc] init];

		_directoryName = [NSUUID UUID].UUIDString;

		_lastSentDevice = @{};
		_lastSentPerson = @{};
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		_appRelease = [coder decodeObjectOfClass:[ApptentiveAppRelease class] forKey:AppReleaseKey];
		_SDK = [coder decodeObjectOfClass:[ApptentiveSDK class] forKey:SDKKey];
		_person = [coder decodeObjectOfClass:[ApptentivePerson class] forKey:PersonKey];
		_device = [coder decodeObjectOfClass:[ApptentiveDevice class] forKey:DeviceKey];
		_engagement = [coder decodeObjectOfClass:[ApptentiveEngagement class] forKey:EngagementKey];
		_token = [coder decodeObjectOfClass:[NSString class] forKey:TokenKey];
		_lastMessageID = [coder decodeObjectOfClass:[NSString class] forKey:LastMessageIDKey];
		_mutableUserInfo = [coder decodeObjectOfClass:[NSMutableDictionary class] forKey:MutableUserInfoKey];
		_identifier = [coder decodeObjectOfClass:[NSString class] forKey:IdentifierKey];
		_directoryName = [coder decodeObjectOfClass:[NSString class] forKey:DirectoryNameKey];
		_lastSentDevice = [coder decodeObjectOfClass:[NSDictionary class] forKey:LastSentDeviceKey];
		_lastSentPerson = [coder decodeObjectOfClass:[NSDictionary class] forKey:LastSentPersonKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	[coder encodeObject:self.appRelease forKey:AppReleaseKey];
	[coder encodeObject:self.SDK forKey:SDKKey];
	[coder encodeObject:self.person forKey:PersonKey];
	[coder encodeObject:self.device forKey:DeviceKey];
	[coder encodeObject:self.engagement forKey:EngagementKey];
	[coder encodeObject:self.token forKey:TokenKey];
	[coder encodeObject:self.lastMessageID forKey:LastMessageIDKey];
	[coder encodeObject:self.mutableUserInfo forKey:MutableUserInfoKey];
	[coder encodeObject:self.identifier forKey:IdentifierKey];
	[coder encodeObject:self.directoryName forKey:DirectoryNameKey];
	[coder encodeObject:self.lastSentDevice forKey:LastSentDeviceKey];
	[coder encodeObject:self.lastSentPerson forKey:LastSentPersonKey];
	[coder encodeObject:@1 forKey:ArchiveVersionKey];
}

- (void)setToken:(NSString *)token conversationID:(NSString *)conversationID personID:(NSString *)personID deviceID:(NSString *)deviceID {
	[self setConversationIdentifier:conversationID JWT:token];
	self.person.identifier = personID;
	self.device.identifier = deviceID;
}

- (void)setConversationIdentifier:(NSString *)identifier JWT:(NSString *)JWT {
	_identifier = [identifier copy];
	_token = [JWT copy];
}

- (void)checkForDiffs {
	@synchronized(self) {
		ApptentiveAppRelease *currentAppRelease = [[ApptentiveAppRelease alloc] initWithCurrentAppRelease];
		if (self.appRelease.overridingStyles) {
			[currentAppRelease setOverridingStyles];
		}

		ApptentiveSDK *currentSDK = [[ApptentiveSDK alloc] initWithCurrentSDK];

		BOOL conversationNeedsUpdate = NO;

		NSDictionary *appReleaseDiffs = [ApptentiveUtilities diffDictionary:currentAppRelease.JSONDictionary againstDictionary:self.appRelease.JSONDictionary];

		if (appReleaseDiffs.count > 0) {
			conversationNeedsUpdate = YES;

			if (![currentAppRelease.version isEqualToVersion:self.appRelease.version]) {
				[self.appRelease resetVersion];
				[self.engagement resetVersion];
			}

			if (![currentAppRelease.build isEqualToVersion:self.appRelease.build]) {
				[self.appRelease resetBuild];
				[self.engagement resetBuild];
			}

			_appRelease = currentAppRelease;
		}

		NSDictionary *SDKDiffs = [ApptentiveUtilities diffDictionary:currentSDK.JSONDictionary againstDictionary:self.SDK.JSONDictionary];

		if (SDKDiffs.count > 0) {
			conversationNeedsUpdate = YES;

			_SDK = currentSDK;
		}

		if (conversationNeedsUpdate) {
			[self notifyConversationChanged];

			if ([_delegate respondsToSelector:@selector(conversationAppReleaseOrSDKDidChange:)]) {
				[_delegate conversationAppReleaseOrSDKDidChange:self];
			}
		}

		// See if any of the non-custom device attributes have changed
		ApptentiveDevice *device = [[ApptentiveDevice alloc] initWithCurrentDevice];
		device.integrationConfiguration = self.device.integrationConfiguration;

		NSDictionary *deviceDiffs = [ApptentiveUtilities diffDictionary:device.JSONDictionary againstDictionary:self.device.JSONDictionary];

		if (deviceDiffs.count > 0) {
			[self.delegate conversation:self deviceDidChange:deviceDiffs];
			self.lastSentDevice = self.device.JSONDictionary;
		}
	}
}

- (void)checkForDeviceDiffs {
	ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Diffing device");

	NSDictionary *deviceDiffs = [ApptentiveUtilities diffDictionary:self.device.JSONDictionary againstDictionary:self.lastSentDevice];

	if (deviceDiffs.count > 0) {
		ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Device diffs found: %@", deviceDiffs);

		[self.delegate conversation:self deviceDidChange:deviceDiffs];
		self.lastSentDevice = self.device.JSONDictionary;
	}
}

- (void)checkForPersonDiffs {
	ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Diffing person");

	NSDictionary *personDiffs = [ApptentiveUtilities diffDictionary:self.person.JSONDictionary againstDictionary:self.lastSentPerson];

	if (personDiffs.count > 0) {
		ApptentiveLogVerbose(ApptentiveLogTagConversation, @"Person diffs found: %@", personDiffs);

		[self.delegate conversation:self personDidChange:personDiffs];
		self.lastSentPerson = self.person.JSONDictionary;
	}
}

- (void)notifyConversationChanged {
	if ([_delegate respondsToSelector:@selector(conversationDidChange:)]) {
		[_delegate conversationDidChange:self];
	}
}

- (void)notifyConversationEngagementDidChange {
	[self notifyConversationChanged];

	if ([_delegate respondsToSelector:@selector(conversationEngagementDidChange:)]) {
		[_delegate conversationEngagementDidChange:self];
	}
}

- (void)warmCodePoint:(NSString *)codePoint {
	[self.engagement warmCodePoint:codePoint];
}

- (void)engageCodePoint:(NSString *)codePoint {
	[self.engagement engageCodePoint:codePoint];

	[self notifyConversationEngagementDidChange];
}

- (void)warmInteraction:(NSString *)codePoint {
	[self.engagement warmInteraction:codePoint];
}

- (void)engageInteraction:(NSString *)interactionIdentifier {
	[self.engagement engageInteraction:interactionIdentifier];

	[self notifyConversationEngagementDidChange];
}

- (void)didOverrideStyles {
	if (!self.appRelease.overridingStyles) {
		[self.appRelease setOverridingStyles];

		[self checkForDiffs];
	}
}

- (void)didDownloadMessagesUpTo:(NSString *)lastMessageID {
	_lastMessageID = lastMessageID;
}

- (NSDate *)currentTime {
	return [NSDate date];
}

- (NSDictionary *)appReleaseSDKJSON {
	NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:self.appRelease.JSONDictionary];
	[result addEntriesFromDictionary:self.SDK.JSONDictionary];

	return result;
}

- (instancetype)initAndMigrate {
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"ATEngagementInstallDateKey"]) {
		return nil;
	}

	self = [super init];

	if (self) {
        _state = ApptentiveConversationStateLegacyPending;
		_appRelease = [[ApptentiveAppRelease alloc] initAndMigrate];
		_SDK = [[ApptentiveSDK alloc] initAndMigrate];
		_person = [[ApptentivePerson alloc] initAndMigrate];
		_device = [[ApptentiveDevice alloc] initAndMigrate];
		_engagement = [[ApptentiveEngagement alloc] initAndMigrate];

		_directoryName = [NSUUID UUID].UUIDString;

		NSData *legacyConversationData = [[NSUserDefaults standardUserDefaults] dataForKey:ATCurrentConversationPreferenceKey];

		[NSKeyedUnarchiver setClass:[ApptentiveLegacyConversation class] forClassName:@"ApptentiveConversation"];
		[NSKeyedUnarchiver setClass:[ApptentiveLegacyConversation class] forClassName:@"ATConversation"];

		ApptentiveLegacyConversation *legacyConversation = (ApptentiveLegacyConversation *)[NSKeyedUnarchiver unarchiveObjectWithData:legacyConversationData];

		[NSKeyedUnarchiver setClass:[self class] forClassName:@"ApptentiveConversation"];

		// we only need a legacy token here: jwt-token and conversation id would be fetched later
		_legacyToken = legacyConversation.token;
		_person.identifier = legacyConversation.personID;
		_device.identifier = legacyConversation.deviceID;

		_mutableUserInfo = [NSMutableDictionary dictionary];

		NSString *draftMessage = [[NSUserDefaults standardUserDefaults] stringForKey:ATMessageCenterDraftMessageKey];

		if (draftMessage) {
			[_mutableUserInfo setObject:draftMessage forKey:ATMessageCenterDraftMessageKey];
		}

		[_mutableUserInfo setObject:@([[NSUserDefaults standardUserDefaults] boolForKey:ATMessageCenterDidSkipProfileKey]) forKey:ATMessageCenterDidSkipProfileKey];

		// Migrate last sent device if available
		_lastSentDevice = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ATDeviceLastUpdateValuePreferenceKey][@"device"] ?: @{};

		// Migrate last sent person if available
		NSData *lastSentPersondata = [[NSUserDefaults standardUserDefaults] dataForKey:ATPersonLastUpdateValuePreferenceKey];

		if (lastSentPersondata) {
			NSDictionary *person = [NSKeyedUnarchiver unarchiveObjectWithData:lastSentPersondata];
			if ([person isKindOfClass:[NSDictionary class]]) {
				_lastSentPerson = person[@"person"];
			} else {
				_lastSentPerson = @{};
			}
		} else {
			_lastSentPerson = @{};
		}
	}

	return self;
}

+ (void)deleteMigratedData {
	[ApptentiveAppRelease deleteMigratedData];
	[ApptentiveSDK deleteMigratedData];
	[ApptentivePerson deleteMigratedData];
	[ApptentiveDevice deleteMigratedData];
	[ApptentiveEngagement deleteMigratedData];

	[[NSUserDefaults standardUserDefaults] removeObjectForKey:ATCurrentConversationPreferenceKey];
}

- (NSDictionary *)userInfo {
	return [NSDictionary dictionaryWithDictionary:self.mutableUserInfo];
}

- (void)setUserInfo:(NSObject *)object forKey:(NSString *)key {
	if (object != nil && key != nil) {
		[self.mutableUserInfo setObject:object forKey:key];

		[self notifyConversationChanged];

		if ([_delegate respondsToSelector:@selector(conversationUserInfoDidChange:)]) {
			[_delegate conversationUserInfoDidChange:self];
		}
	} else {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Attempting to set user info with nil key and/or value");
	}
}

- (void)removeUserInfoForKey:(NSString *)key {
	if (key != nil) {
		[self.mutableUserInfo removeObjectForKey:key];
	} else {
		ApptentiveLogError(ApptentiveLogTagConversation, @"Attempting to set user info with nil key and/or value");
	}
}

- (void)setPushToken:(NSString *)pushToken provider:(ApptentivePushProvider)pushProvider {
	NSMutableDictionary *integrationConfiguration = [self.device.integrationConfiguration mutableCopy];

	[integrationConfiguration removeObjectForKey:[self integrationKeyForPushProvider:ApptentivePushProviderApptentive]];
	[integrationConfiguration removeObjectForKey:[self integrationKeyForPushProvider:ApptentivePushProviderUrbanAirship]];
	[integrationConfiguration removeObjectForKey:[self integrationKeyForPushProvider:ApptentivePushProviderAmazonSNS]];
	[integrationConfiguration removeObjectForKey:[self integrationKeyForPushProvider:ApptentivePushProviderParse]];

	[integrationConfiguration setObject:@{ @"token": pushToken } forKey:[self integrationKeyForPushProvider:pushProvider]];

	self.device.integrationConfiguration = integrationConfiguration;
}

- (NSString *)integrationKeyForPushProvider:(ApptentivePushProvider)pushProvider {
	switch (pushProvider) {
		case ApptentivePushProviderApptentive:
			return @"apptentive_push";
		case ApptentivePushProviderUrbanAirship:
			return @"urban_airship";
		case ApptentivePushProviderAmazonSNS:
			return @"aws_sns";
		case ApptentivePushProviderParse:
			return @"parse";
		default:
			return @"UNKNOWN_PUSH_PROVIDER";
	}
}

#pragma mark - Mutability

- (id)mutableCopy {
    ApptentiveMutableConversation *result = [[ApptentiveMutableConversation alloc] init];
    result.state = self.state;
    result.token = self.token;
    result.legacyToken = self.legacyToken;
    result.userId = self.userId;
    result.encryptionKey = self.encryptionKey;
    result.appRelease = self.appRelease;
    result.SDK = self.SDK;
    result.person = self.person;
    result.device = self.device;
    result.engagement = self.engagement;
    result.mutableUserInfo = self.mutableUserInfo;
    result.lastSentPerson = self.lastSentPerson;
    result.lastSentDevice = self.lastSentDevice;
    result.identifier = self.identifier;
    result.lastMessageID = self.lastMessageID;
    result.delegate = self.delegate;
    result.directoryName = self.directoryName;
    return result;
}


@end

@implementation ApptentiveLegacyConversation

+ (void)load {
	[NSKeyedUnarchiver setClass:self forClassName:@"ATConversation"];
}

- (id)initWithCoder:(NSCoder *)coder {
	self = [super init];

	if (self) {
		_token = [coder decodeObjectForKey:@"token"];
		_personID = [coder decodeObjectForKey:@"personID"];
		_deviceID = [coder decodeObjectForKey:@"deviceID"];
	}

	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
	[coder encodeObject:self.token forKey:@"token"];
	[coder encodeObject:self.personID forKey:@"personID"];
	[coder encodeObject:self.deviceID forKey:@"deviceID"];
}

@end

@interface ApptentiveMutableConversation ()

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *lastMessageID;
@property (strong, nonatomic) NSString *directoryName;

@end

@implementation ApptentiveMutableConversation

@dynamic mutableUserInfo;
@dynamic lastSentPerson;
@dynamic lastSentDevice;
@dynamic state;
@dynamic appRelease;
@dynamic SDK;
@dynamic person;
@dynamic device;
@dynamic engagement;
@dynamic token;
@dynamic identifier;
@dynamic legacyToken;
@dynamic userId;
@dynamic encryptionKey;
@dynamic lastMessageID;
@dynamic directoryName;

// FIXME: remove these methods

- (void)setToken:(NSString *)token conversationID:(NSString *)conversationID personID:(NSString *)personID deviceID:(NSString *)deviceID {
    [self setConversationIdentifier:conversationID JWT:token];
    self.person.identifier = personID;
    self.device.identifier = deviceID;
}

- (void)setConversationIdentifier:(NSString *)identifier JWT:(NSString *)JWT {
    self.identifier = identifier;
    self.token = JWT;
}

@end
