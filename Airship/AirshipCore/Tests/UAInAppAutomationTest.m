/* Copyright Airship and Contributors */

#import "UAAirshipBaseTest.h"

#import "UAirship+Internal.h"
#import "UAInAppMessageManager+Internal.h"
#import "UASchedule+Internal.h"
#import "UAPreferenceDataStore+Internal.h"
#import "UAScheduleAudience.h"
#import "UAScheduleAudienceChecks+Internal.h"
#import "UATagSelector+Internal.h"
#import "UAInAppMessage+Internal.h"
#import "UAInAppRemoteDataClient+Internal.h"
#import "UAComponent+Internal.h"
#import "UAInAppAutomation+Internal.h"
#import "UAInAppMessageCustomDisplayContent+Internal.h"
#import "UADeferredSchedule+Internal.h"

@interface UAInAppAutomationTest : UAAirshipBaseTest
@property(nonatomic, strong) UAInAppAutomation *inAppAutomation;
@property(nonatomic, strong) id mockAutomationEngine;
@property(nonatomic, strong) id mockAudienceManager;
@property(nonatomic, strong) id mockRemoteDataClient;
@property(nonatomic, strong) id mockInAppMessageManager;
@property(nonatomic, strong) id mockAirship;
@property(nonatomic, strong) id mockDeferredClient;
@property(nonatomic, strong) id mockChannel;

@property(nonatomic, strong) id<UAAutomationEngineDelegate> engineDelegate;
@end

@implementation UAInAppAutomationTest

- (void)setUp {
    [super setUp];

    self.mockAirship = [self mockForClass:[UAirship class]];
    [[[self.mockAirship stub] andReturnValue:@(YES)] isDataCollectionEnabled];
    [UAirship setSharedAirship:self.mockAirship];

    self.mockAutomationEngine = [self mockForClass:[UAAutomationEngine class]];
    self.mockAudienceManager = [self mockForClass:[UAInAppAudienceManager class]];
    self.mockRemoteDataClient = [self mockForClass:[UAInAppRemoteDataClient class]];
    self.mockInAppMessageManager = [self mockForClass:[UAInAppMessageManager class]];
    self.mockDeferredClient = [self mockForClass:[UADeferredScheduleAPIClient class]];
    self.mockChannel = [self mockForClass:[UAChannel class]];

    [[[self.mockAutomationEngine stub] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:2];
        self.engineDelegate =  (__bridge id<UAAutomationEngineDelegate>)arg;
    }] setDelegate:OCMOCK_ANY];

    self.inAppAutomation = [UAInAppAutomation automationWithEngine:self.mockAutomationEngine
                                                   audienceManager:self.mockAudienceManager
                                                  remoteDataClient:self.mockRemoteDataClient
                                                         dataStore:self.dataStore
                                               inAppMessageManager:self.mockInAppMessageManager
                                                           channel:self.mockChannel
                                         deferredScheduleAPIClient:self.mockDeferredClient];
    XCTAssertNotNil(self.engineDelegate);
}

- (void)testCheckEmptyAudience {
    UAScheduleAudience *emptyAudience = [UAScheduleAudience audienceWithBuilderBlock:^(UAScheduleAudienceBuilder *builder) {
    }];

    XCTestExpectation *checkFinished = [self expectationWithDescription:@"check audience finished"];
    [self.inAppAutomation checkAudience:emptyAudience completionHandler:^(BOOL inAudience, NSError * _Nullable error) {
        XCTAssertTrue(inAudience);
        XCTAssertNil(error);
        [checkFinished fulfill];
    }];

    [self waitForTestExpectations];
}

- (void)testCheckTagGroupAudience {
    UAScheduleAudience *audience = [UAScheduleAudience audienceWithBuilderBlock:^(UAScheduleAudienceBuilder *builder) {
        builder.tagSelector = [UATagSelector tag:@"neat" group:@"group"];
    }];

    UATagGroups *tagResponse = [UATagGroups tagGroupsWithTags:@{@"group" : @[@"neat"]}];
    [[[self.mockAudienceManager expect] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        void(^completionHandler)(UATagGroups * _Nullable tagGroups, NSError *error);
        completionHandler = (__bridge void(^)(UATagGroups * _Nullable tagGroups, NSError *error))arg;
        completionHandler(tagResponse, nil);
    }] getTagGroups:OCMOCK_ANY completionHandler:OCMOCK_ANY];


    XCTestExpectation *checkFinished = [self expectationWithDescription:@"check audience finished"];
    [self.inAppAutomation checkAudience:audience completionHandler:^(BOOL inAudience, NSError * _Nullable error) {
        XCTAssertTrue(inAudience);
        XCTAssertNil(error);
        [checkFinished fulfill];
    }];

    [self waitForTestExpectations];
}

- (void)testCheckTagGroupAudienceError {
    UAScheduleAudience *audience = [UAScheduleAudience audienceWithBuilderBlock:^(UAScheduleAudienceBuilder *builder) {
        builder.tagSelector = [UATagSelector tag:@"neat" group:@"group"];
    }];

    NSError *error = [NSError errorWithDomain:@"com.urbanairship.test" code:1 userInfo:nil];
    [[[self.mockAudienceManager expect] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        void(^completionHandler)(UATagGroups * _Nullable tagGroups, NSError *error);
        completionHandler = (__bridge void(^)(UATagGroups * _Nullable tagGroups, NSError *error))arg;
        completionHandler(nil, error);    }] getTagGroups:OCMOCK_ANY completionHandler:OCMOCK_ANY];


    XCTestExpectation *checkFinished = [self expectationWithDescription:@"check audience finished"];
    [self.inAppAutomation checkAudience:audience completionHandler:^(BOOL inAudience, NSError * _Nullable error) {
        XCTAssertFalse(inAudience);
        XCTAssertNotNil(error);
        [checkFinished fulfill];
    }];

    [self waitForTestExpectations];
}

- (void)testCheckTagGroupAudienceNotInAudience {
    UAScheduleAudience *audience = [UAScheduleAudience audienceWithBuilderBlock:^(UAScheduleAudienceBuilder *builder) {
        builder.tagSelector = [UATagSelector tag:@"neat" group:@"group"];
    }];

    UATagGroups *tagResponse = [UATagGroups tagGroupsWithTags:@{@"group" : @[]}];
    [[[self.mockAudienceManager expect] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        void(^completionHandler)(UATagGroups * _Nullable tagGroups, NSError *error);
        completionHandler = (__bridge void(^)(UATagGroups * _Nullable tagGroups, NSError *error))arg;
        completionHandler(tagResponse, nil);
    }] getTagGroups:OCMOCK_ANY completionHandler:OCMOCK_ANY];

    XCTestExpectation *checkFinished = [self expectationWithDescription:@"check audience finished"];
    [self.inAppAutomation checkAudience:audience completionHandler:^(BOOL inAudience, NSError * _Nullable error) {
        XCTAssertFalse(inAudience);
        XCTAssertNil(error);
        [checkFinished fulfill];
    }];

    [self waitForTestExpectations];
}

- (void)testPrepareMessage {
    UAInAppMessage *message = [UAInAppMessage messageWithBuilderBlock:^(UAInAppMessageBuilder *builder) {
        builder.displayContent = [UAInAppMessageCustomDisplayContent displayContentWithValue:@{}];
    }];

    UASchedule *schedule = [UAInAppMessageSchedule scheduleWithMessage:message builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[[UAScheduleTrigger foregroundTriggerWithCount:1]];
        builder.identifier = @"schedule ID";
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];

    [[self.mockInAppMessageManager expect] prepareMessage:message
                                               scheduleID:@"schedule ID"
                                        completionHandler:[OCMArg checkWithBlock:^BOOL(id obj) {
        void(^completionBlock)(UAInAppMessagePrepareResult) = obj;
        completionBlock(UAInAppMessagePrepareResultSuccess);
        return YES;
    }]];

    [self.engineDelegate prepareSchedule:schedule triggerContext:nil completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultContinue, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockInAppMessageManager verify];
}

- (void)testPrepareActions {
    UASchedule *schedule = [UAActionSchedule scheduleWithActions:@{} builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[[UAScheduleTrigger foregroundTriggerWithCount:1]];
        builder.identifier = @"schedule ID";
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];

    [self.engineDelegate prepareSchedule:schedule triggerContext:nil completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultContinue, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
}

- (void)testPrepareDeferred {
    [[[self.mockChannel stub] andReturn:@"channel ID"] identifier];
    UAInAppMessage *message = [UAInAppMessage messageWithBuilderBlock:^(UAInAppMessageBuilder *builder) {
        builder.displayContent = [UAInAppMessageCustomDisplayContent displayContentWithValue:@{}];
    }];

    UADeferredScheduleResult *deferredResult = [UADeferredScheduleResult resultWithMessage:message audienceMatch:YES];

    UAScheduleTrigger *trigger = [UAScheduleTrigger foregroundTriggerWithCount:1];

    UAScheduleTriggerContext *triggerContext = [UAScheduleTriggerContext triggerContextWithTrigger:trigger
                                                                                             event:@"some event"];
    UAScheduleDeferredData *deferred = [UAScheduleDeferredData deferredDataWithURL:[NSURL URLWithString:@"https://airship.com"]
                                                                retriableOnTimeout:YES];

    UASchedule *schedule = [UADeferredSchedule scheduleWithDeferredData:deferred builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[trigger];
        builder.identifier = @"schedule ID";
    }];

    UATagGroupsMutation *mutation = [UATagGroupsMutation mutationToAddTags:@[@"neat", @"rad"] group:@"cool"];
    UATagGroupsMutation *mutation2 = [UATagGroupsMutation mutationToAddTags:@[@"awesome", @"nice"] group:@"great"];

    NSArray<UATagGroupsMutation *> *tagOverrides = @[mutation, mutation2];

    UAAttributeMutations *attributeMutations = [UAAttributeMutations mutations];
    [attributeMutations setString:@"absolutely" forAttribute:@"fabulous"];
    UAAttributePendingMutations *attributeOverrides = [UAAttributePendingMutations pendingMutationsWithMutations:attributeMutations
                                                                                                             date:[[UADate alloc] init]];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    [[[self.mockInAppMessageManager expect] andDo:^(NSInvocation *invocation) {
        void (^block)(UAInAppMessagePrepareResult);
        [invocation getArgument:&block atIndex:4];
        block(UAInAppMessagePrepareResultSuccess);
    }] prepareMessage:message scheduleID:@"schedule ID" completionHandler:OCMOCK_ANY];

    [[[self.mockAudienceManager expect] andReturn:tagOverrides] tagOverrides];
    [[[self.mockAudienceManager expect] andReturn:attributeOverrides] attributeOverrides];

    [[[self.mockDeferredClient expect] andDo:^(NSInvocation *invocation) {
        void (^block)(UADeferredScheduleResult *, NSError *);
        [invocation getArgument:&block atIndex:7];
        block(deferredResult, nil);
    }] resolveURL:deferred.URL
        channelID:@"channel ID" triggerContext:triggerContext
     tagOverrides:tagOverrides attributeOverrides:attributeOverrides completionHandler:OCMOCK_ANY];

    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];
    [self.engineDelegate prepareSchedule:schedule
                          triggerContext:triggerContext
                       completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultContinue, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockDeferredClient verify];
    [self.mockInAppMessageManager verify];
    [self.mockAudienceManager verify];
}

- (void)testPrepareDeferredTimedOut {
    [[[self.mockChannel stub] andReturn:@"channel ID"] identifier];

    NSError *deferredResult = [NSError errorWithDomain:UADeferredScheduleAPIClientErrorDomain
                                                  code:UADeferredScheduleAPIClientErrorTimedOut
                                              userInfo:nil];

    UAScheduleDeferredData *deferred = [UAScheduleDeferredData deferredDataWithURL:[NSURL URLWithString:@"https://airship.com"]
                                                                retriableOnTimeout:NO];

    UASchedule *schedule = [UADeferredSchedule scheduleWithDeferredData:deferred builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[[UAScheduleTrigger foregroundTriggerWithCount:1]];
        builder.identifier = @"schedule ID";
    }];

    UATagGroupsMutation *mutation = [UATagGroupsMutation mutationToAddTags:@[@"neat", @"rad"] group:@"cool"];
    UATagGroupsMutation *mutation2 = [UATagGroupsMutation mutationToAddTags:@[@"awesome", @"nice"] group:@"great"];

    NSArray<UATagGroupsMutation *> *tagOverrides = @[mutation, mutation2];

    UAAttributeMutations *attributeMutations = [UAAttributeMutations mutations];
    [attributeMutations setString:@"absolutely" forAttribute:@"fabulous"];
    UAAttributePendingMutations *attributeOverrides = [UAAttributePendingMutations pendingMutationsWithMutations:attributeMutations
                                                                                                             date:[[UADate alloc] init]];

    [[[self.mockAudienceManager expect] andReturn:tagOverrides] tagOverrides];
    [[[self.mockAudienceManager expect] andReturn:attributeOverrides] attributeOverrides];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    [[[self.mockDeferredClient expect] andDo:^(NSInvocation *invocation) {
        void (^block)(UADeferredScheduleResult *, NSError *);
        [invocation getArgument:&block atIndex:7];
        block(nil, deferredResult);
    }] resolveURL:deferred.URL channelID:@"channel ID" triggerContext:nil
     tagOverrides:tagOverrides attributeOverrides:attributeOverrides completionHandler:OCMOCK_ANY];

    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];
    [self.engineDelegate prepareSchedule:schedule
                          triggerContext:nil
                       completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultPenalize, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockDeferredClient verify];
}

- (void)testPrepareDeferredAudienceMiss {
    [[[self.mockChannel stub] andReturn:@"channel ID"] identifier];

    UADeferredScheduleResult *deferredResult = [UADeferredScheduleResult resultWithMessage:nil audienceMatch:NO];

    UAScheduleDeferredData *deferred = [UAScheduleDeferredData deferredDataWithURL:[NSURL URLWithString:@"https://airship.com"]
                                                                retriableOnTimeout:NO];

    UASchedule *schedule = [UADeferredSchedule scheduleWithDeferredData:deferred builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[[UAScheduleTrigger foregroundTriggerWithCount:1]];
        builder.identifier = @"schedule ID";
        builder.audience = [UAScheduleAudience audienceWithBuilderBlock:^(UAScheduleAudienceBuilder * _Nonnull builder) {
            builder.missBehavior = UAScheduleAudienceMissBehaviorSkip;
        }];
    }];

    UATagGroupsMutation *mutation = [UATagGroupsMutation mutationToAddTags:@[@"neat", @"rad"] group:@"cool"];
    UATagGroupsMutation *mutation2 = [UATagGroupsMutation mutationToAddTags:@[@"awesome", @"nice"] group:@"great"];

    NSArray<UATagGroupsMutation *> *tagOverrides = @[mutation, mutation2];

    UAAttributeMutations *attributeMutations = [UAAttributeMutations mutations];
    [attributeMutations setString:@"absolutely" forAttribute:@"fabulous"];
    UAAttributePendingMutations *attributeOverrides = [UAAttributePendingMutations pendingMutationsWithMutations:attributeMutations
                                                                                                             date:[[UADate alloc] init]];

    [[[self.mockAudienceManager expect] andReturn:tagOverrides] tagOverrides];
    [[[self.mockAudienceManager expect] andReturn:attributeOverrides] attributeOverrides];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    [[[self.mockDeferredClient expect] andDo:^(NSInvocation *invocation) {
        void (^block)(UADeferredScheduleResult *, NSError *);
        [invocation getArgument:&block atIndex:7];
        block(deferredResult, nil);
    }] resolveURL:deferred.URL channelID:@"channel ID" triggerContext:nil
     tagOverrides:tagOverrides attributeOverrides:attributeOverrides completionHandler:OCMOCK_ANY];


    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];
    [self.engineDelegate prepareSchedule:schedule
                          triggerContext:nil
                       completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultSkip, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockDeferredClient verify];
}

- (void)testPrepareDeferredNoMessage {
    [[[self.mockChannel stub] andReturn:@"channel ID"] identifier];

    UADeferredScheduleResult *deferredResult = [UADeferredScheduleResult resultWithMessage:nil audienceMatch:YES];

    UAScheduleDeferredData *deferred = [UAScheduleDeferredData deferredDataWithURL:[NSURL URLWithString:@"https://airship.com"]
                                                                retriableOnTimeout:NO];

    UASchedule *schedule = [UADeferredSchedule scheduleWithDeferredData:deferred builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[[UAScheduleTrigger foregroundTriggerWithCount:1]];
        builder.identifier = @"schedule ID";
        builder.audience = [UAScheduleAudience audienceWithBuilderBlock:^(UAScheduleAudienceBuilder * _Nonnull builder) {
            builder.missBehavior = UAScheduleAudienceMissBehaviorSkip;
        }];
    }];

    UATagGroupsMutation *mutation = [UATagGroupsMutation mutationToAddTags:@[@"neat", @"rad"] group:@"cool"];
    UATagGroupsMutation *mutation2 = [UATagGroupsMutation mutationToAddTags:@[@"awesome", @"nice"] group:@"great"];

    NSArray<UATagGroupsMutation *> *tagOverrides = @[mutation, mutation2];

    UAAttributeMutations *attributeMutations = [UAAttributeMutations mutations];
    [attributeMutations setString:@"absolutely" forAttribute:@"fabulous"];
    UAAttributePendingMutations *attributeOverrides = [UAAttributePendingMutations pendingMutationsWithMutations:attributeMutations
                                                                                                             date:[[UADate alloc] init]];

    [[[self.mockAudienceManager expect] andReturn:tagOverrides] tagOverrides];
    [[[self.mockAudienceManager expect] andReturn:attributeOverrides] attributeOverrides];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    [[[self.mockDeferredClient expect] andDo:^(NSInvocation *invocation) {
        void (^block)(UADeferredScheduleResult *, NSError *);
        [invocation getArgument:&block atIndex:7];
        block(deferredResult, nil);
    }] resolveURL:deferred.URL channelID:@"channel ID" triggerContext:nil
     tagOverrides:tagOverrides attributeOverrides:attributeOverrides completionHandler:OCMOCK_ANY];

    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];
    [self.engineDelegate prepareSchedule:schedule
                          triggerContext:nil
                       completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultPenalize, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockDeferredClient verify];
}

- (void)testPrepareScheduleInvalid {
    UASchedule *schedule = [[UASchedule alloc] init];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(NO)] isScheduleUpToDate:schedule];

    [[[self.mockRemoteDataClient stub] andDo:^(NSInvocation *invocation) {
        void (^block)(void);
        [invocation getArgument:&block atIndex:2];
        block();
    }] notifyOnUpdate:OCMOCK_ANY];

    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];
    [self.engineDelegate prepareSchedule:schedule triggerContext:nil completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultInvalidate, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
}


- (void)testPrepareAudienceCheckFailureDefaultMissBehavior {
    UASchedule *schedule = [UAActionSchedule scheduleWithActions:@{} builderBlock:^(UAScheduleBuilder *builder) {
        builder.audience = [UAScheduleAudience audienceWithBuilderBlock:^(UAScheduleAudienceBuilder *builder) {
            builder.notificationsOptIn = @(YES);
        }];
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    // Mock the checks to reject the audience
    id checks = [self mockForClass:[UAScheduleAudienceChecks class]];
    [[[checks expect] andReturnValue:@(NO)] checkDisplayAudienceConditions:schedule.audience tagGroups:nil];

    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];

    [self.engineDelegate prepareSchedule:schedule triggerContext:nil completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultPenalize, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
    [checks verify];
}

- (void)testPrepareAudienceCheckFailureMissBehaviorCancel {
    UASchedule *schedule = [UAActionSchedule scheduleWithActions:@{} builderBlock:^(UAScheduleBuilder *builder) {
        builder.audience = [UAScheduleAudience audienceWithBuilderBlock:^(UAScheduleAudienceBuilder *builder) {
            builder.notificationsOptIn = @(YES);
            builder.missBehavior = UAScheduleAudienceMissBehaviorCancel;
        }];
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    // Mock the checks to reject the audience
    id checks = [self mockForClass:[UAScheduleAudienceChecks class]];
    [[[checks expect] andReturnValue:@(NO)] checkDisplayAudienceConditions:schedule.audience tagGroups:nil];

    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];

    [self.engineDelegate prepareSchedule:schedule triggerContext:nil completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultCancel, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
    [checks verify];
}

- (void)testPrepareAudienceCheckFailureMissBehaviorSkip {
    UASchedule *schedule = [UAActionSchedule scheduleWithActions:@{} builderBlock:^(UAScheduleBuilder *builder) {
        builder.audience = [UAScheduleAudience audienceWithBuilderBlock:^(UAScheduleAudienceBuilder *builder) {
            builder.notificationsOptIn = @(YES);
            builder.missBehavior = UAScheduleAudienceMissBehaviorSkip;
        }];
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    // Mock the checks to reject the audience
    id checks = [self mockForClass:[UAScheduleAudienceChecks class]];
    [[[checks expect] andReturnValue:@(NO)] checkDisplayAudienceConditions:schedule.audience tagGroups:nil];

    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];

    [self.engineDelegate prepareSchedule:schedule triggerContext:nil completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultSkip, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
    [checks verify];
}

- (void)testPrepareAudienceCheckFailureMissBehaviorPenalize {
    UASchedule *schedule = [UAActionSchedule scheduleWithActions:@{} builderBlock:^(UAScheduleBuilder *builder) {
        builder.audience = [UAScheduleAudience audienceWithBuilderBlock:^(UAScheduleAudienceBuilder *builder) {
            builder.notificationsOptIn = @(YES);
            builder.missBehavior = UAScheduleAudienceMissBehaviorPenalize;
        }];
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    // Mock the checks to reject the audience
    id checks = [self mockForClass:[UAScheduleAudienceChecks class]];
    [[[checks expect] andReturnValue:@(NO)] checkDisplayAudienceConditions:schedule.audience tagGroups:nil];

    XCTestExpectation *prepareFinished = [self expectationWithDescription:@"prepare finished"];

    [self.engineDelegate prepareSchedule:schedule triggerContext:nil completionHandler:^(UAAutomationSchedulePrepareResult result) {
        XCTAssertEqual(UAAutomationSchedulePrepareResultPenalize, result);
        [prepareFinished fulfill];
    }];

    [self waitForTestExpectations];
    [checks verify];
}

- (void)testIsActionsReady {
    UASchedule *schedule = [UAActionSchedule scheduleWithActions:@{} builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[[UAScheduleTrigger foregroundTriggerWithCount:1]];
        builder.identifier = @"schedule ID";
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    UAAutomationScheduleReadyResult result = [self.engineDelegate isScheduleReadyToExecute:schedule];

    XCTAssertEqual(UAAutomationScheduleReadyResultContinue, result);
}

- (void)testIsMessageReady {
    UAInAppMessage *message = [UAInAppMessage messageWithBuilderBlock:^(UAInAppMessageBuilder *builder) {
        builder.displayContent = [UAInAppMessageCustomDisplayContent displayContentWithValue:@{}];
    }];

    UASchedule *schedule = [UAInAppMessageSchedule scheduleWithMessage:message builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[[UAScheduleTrigger foregroundTriggerWithCount:1]];
        builder.identifier = @"schedule ID";
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    [[[self.mockInAppMessageManager expect] andReturnValue:@(UAAutomationScheduleReadyResultContinue)] isReadyToDisplay:@"schedule ID"];

    UAAutomationScheduleReadyResult result = [self.engineDelegate isScheduleReadyToExecute:schedule];

    XCTAssertEqual(UAAutomationScheduleReadyResultContinue, result);
}

- (void)testIsMessageNotReady {
    UAInAppMessage *message = [UAInAppMessage messageWithBuilderBlock:^(UAInAppMessageBuilder *builder) {
        builder.displayContent = [UAInAppMessageCustomDisplayContent displayContentWithValue:@{}];
    }];

    UASchedule *schedule = [UAInAppMessageSchedule scheduleWithMessage:message builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[[UAScheduleTrigger foregroundTriggerWithCount:1]];
        builder.identifier = @"schedule ID";
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    [[[self.mockInAppMessageManager expect] andReturnValue:@(UAAutomationScheduleReadyResultNotReady)] isReadyToDisplay:@"schedule ID"];

    UAAutomationScheduleReadyResult result = [self.engineDelegate isScheduleReadyToExecute:schedule];

    XCTAssertEqual(UAAutomationScheduleReadyResultNotReady, result);
}

- (void)testIsMessageReadyInvalid {
    UAInAppMessage *message = [UAInAppMessage messageWithBuilderBlock:^(UAInAppMessageBuilder *builder) {
        builder.displayContent = [UAInAppMessageCustomDisplayContent displayContentWithValue:@{}];
    }];

    UASchedule *schedule = [UAInAppMessageSchedule scheduleWithMessage:message builderBlock:^(UAScheduleBuilder * _Nonnull builder) {
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(NO)] isScheduleUpToDate:schedule];
    [[self.mockInAppMessageManager expect] scheduleExecutionAborted:schedule.identifier];

    UAAutomationScheduleReadyResult result = [self.engineDelegate isScheduleReadyToExecute:schedule];
    XCTAssertEqual(UAAutomationScheduleReadyResultInvalidate, result);
    [self.mockInAppMessageManager verify];
}

- (void)testIsReadyPaused {
    self.inAppAutomation.paused = YES;

    UASchedule *schedule = [[UASchedule alloc] init];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    UAAutomationScheduleReadyResult result = [self.engineDelegate isScheduleReadyToExecute:schedule];
    XCTAssertEqual(UAAutomationScheduleReadyResultNotReady, result);
}

- (void)testExecuteMessage {
    UAInAppMessage *message = [UAInAppMessage messageWithBuilderBlock:^(UAInAppMessageBuilder *builder) {
        builder.displayContent = [UAInAppMessageCustomDisplayContent displayContentWithValue:@{}];
    }];

    UASchedule *schedule = [UAInAppMessageSchedule scheduleWithMessage:message builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[[UAScheduleTrigger foregroundTriggerWithCount:1]];
        builder.identifier = @"schedule ID";
    }];

    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isRemoteSchedule:schedule];
    [[[self.mockRemoteDataClient stub] andReturnValue:@(YES)] isScheduleUpToDate:schedule];

    [[self.mockInAppMessageManager expect] displayMessageWithScheduleID:@"schedule ID" completionHandler:[OCMArg checkWithBlock:^BOOL(id obj) {
        void(^completionBlock)(void) = obj;
        completionBlock();
        return YES;
    }]];

    XCTestExpectation *executeFinished = [self expectationWithDescription:@"execute finished"];
    [self.engineDelegate executeSchedule:schedule completionHandler:^{
        [executeFinished fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockInAppMessageManager verify];
}

- (void)testExecuteActions {
    UASchedule *schedule = [UAActionSchedule scheduleWithActions:@{@"foo": @"bar"} builderBlock:^(UAScheduleBuilder *builder) {
        builder.triggers = @[[UAScheduleTrigger foregroundTriggerWithCount:1]];
        builder.identifier = @"schedule ID";
    }];

    id mockActionRunner = [self mockForClass:[UAActionRunner class]];
    [[mockActionRunner expect] runActionsWithActionValues:schedule.data
                                                situation:UASituationAutomation
                                                 metadata:nil
                                        completionHandler:[OCMArg checkWithBlock:^BOOL(id obj) {
        void (^handler)(UAActionResult *) = obj;
        handler([UAActionResult emptyResult]);
        return YES;
    }]];


    XCTestExpectation *executeFinished = [self expectationWithDescription:@"execute finished"];
    [self.engineDelegate executeSchedule:schedule completionHandler:^{
        [executeFinished fulfill];
    }];

    [self waitForTestExpectations];
    [mockActionRunner verify];
}

- (void)testCancelScheduleWithID {
    [[[self.mockAutomationEngine expect] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        void (^completionHandler)(BOOL) = (__bridge void (^)(BOOL))arg;
        completionHandler(YES);
    }] cancelScheduleWithID:@"some ID" completionHandler:OCMOCK_ANY];

    XCTestExpectation *blockInvoked = [self expectationWithDescription:@"block invoked"];
    [self.inAppAutomation cancelScheduleWithID:@"some ID" completionHandler:^(BOOL cancelled) {
        XCTAssertTrue(cancelled);
        [blockInvoked fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockAutomationEngine verify];
}

- (void)testCancelScheduleWithGroup {
    [[[self.mockAutomationEngine expect] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        void (^completionHandler)(BOOL) = (__bridge void (^)(BOOL))arg;
        completionHandler(YES);
    }] cancelSchedulesWithGroup:@"some group" completionHandler:OCMOCK_ANY];

    XCTestExpectation *blockInvoked = [self expectationWithDescription:@"block invoked"];
    [self.inAppAutomation cancelSchedulesWithGroup:@"some group" completionHandler:^(BOOL cancelled) {
        XCTAssertTrue(cancelled);
        [blockInvoked fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockAutomationEngine verify];
}

- (void)testCancelMessageSchedulesWithGroup {
    [[[self.mockAutomationEngine expect] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:4];
        void (^completionHandler)(BOOL) = (__bridge void (^)(BOOL))arg;
        completionHandler(YES);
    }] cancelSchedulesWithGroup:@"some group" type:UAScheduleTypeInAppMessage completionHandler:OCMOCK_ANY];

    XCTestExpectation *blockInvoked = [self expectationWithDescription:@"block invoked"];
    [self.inAppAutomation cancelMessageSchedulesWithGroup:@"some group" completionHandler:^(BOOL cancelled) {
        XCTAssertTrue(cancelled);
        [blockInvoked fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockAutomationEngine verify];
}

- (void)testCancelActionSchedulesWithGroup {
    [[[self.mockAutomationEngine expect] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:4];
        void (^completionHandler)(BOOL) = (__bridge void (^)(BOOL))arg;
        completionHandler(YES);
    }] cancelSchedulesWithGroup:@"some group" type:UAScheduleTypeActions completionHandler:OCMOCK_ANY];

    XCTestExpectation *blockInvoked = [self expectationWithDescription:@"block invoked"];
    [self.inAppAutomation cancelActionSchedulesWithGroup:@"some group" completionHandler:^(BOOL cancelled) {
        XCTAssertTrue(cancelled);
        [blockInvoked fulfill];
    }];

    [self waitForTestExpectations];
    [self.mockAutomationEngine verify];
}

- (void)testSchedule {
    UASchedule *schedule = [[UASchedule alloc] init];

    // expectations
    [[[self.mockAutomationEngine expect] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        void (^completionHandler)(BOOL) = (__bridge void (^)(BOOL))arg;

        if (completionHandler) {
            completionHandler(YES);
        }
    }] schedule:schedule completionHandler:OCMOCK_ANY];

    // test
    XCTestExpectation *blockInvoked = [self expectationWithDescription:@"block invoked"];
    [self.inAppAutomation schedule:schedule completionHandler:^(BOOL result) {
        XCTAssertTrue(result);
        [blockInvoked fulfill];
    }];

    // verify
    [self waitForTestExpectations];
    [self.mockAutomationEngine verify];
}

- (void)testScheduleMultiple {
    UASchedule *scheduleOne = [[UASchedule alloc] init];
    UASchedule *scheduleTwo = [[UASchedule alloc] init];


    // expectations
    [[[self.mockAutomationEngine expect] andDo:^(NSInvocation *invocation) {
        void *arg;
        [invocation getArgument:&arg atIndex:3];
        void (^completionHandler)(BOOL) = (__bridge void (^)(BOOL))arg;

        if (completionHandler) {
            completionHandler(YES);
        }
    }] scheduleMultiple:@[scheduleOne, scheduleTwo] completionHandler:OCMOCK_ANY];

    // test
    XCTestExpectation *blockInvoked = [self expectationWithDescription:@"block invoked"];
    [self.inAppAutomation scheduleMultiple:@[scheduleOne, scheduleTwo] completionHandler:^(BOOL result) {
        XCTAssertTrue(result);
        [blockInvoked fulfill];
    }];

    // verify
    [self waitForTestExpectations];
    [self.mockAutomationEngine verify];
}

- (void)testComponentEnabled {
    XCTAssertTrue(self.inAppAutomation.componentEnabled);

    // test disable
    [[self.mockAutomationEngine expect] pause];
    self.inAppAutomation.componentEnabled = NO;

    // verify
    XCTAssertFalse(self.inAppAutomation.componentEnabled);
    [self.mockAutomationEngine verify];

    // test enable
    [[self.mockAutomationEngine expect] resume];
    self.inAppAutomation.componentEnabled = YES;

    // verify
    XCTAssertTrue(self.inAppAutomation.componentEnabled);
    [self.mockAutomationEngine verify];
}

- (void)testEnable {
    XCTAssertTrue(self.inAppAutomation.isEnabled);

    // test disable
    [[self.mockAutomationEngine expect] pause];
    self.inAppAutomation.enabled = NO;

    // verify
    XCTAssertFalse(self.inAppAutomation.isEnabled);
    [self.mockAutomationEngine verify];

    // test enable
    [[self.mockAutomationEngine expect] resume];
    self.inAppAutomation.enabled = YES;

    // verify
    XCTAssertTrue(self.inAppAutomation.isEnabled);
    [self.mockAutomationEngine verify];
}

@end


