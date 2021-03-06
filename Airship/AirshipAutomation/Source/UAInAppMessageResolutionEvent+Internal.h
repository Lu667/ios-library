/* Copyright Airship and Contributors */

#import "UAInAppMessage.h"
#import "UAInAppMessageResolution.h"
#import "UAAirshipAutomationCoreImport.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * In-app message resolution event.
 */
@interface UAInAppMessageResolutionEvent : UAEvent

/**
 * Creates a replaced in-app resolution event.
 *
 * @param messageID The replaced message ID.
 * @param replacementID The new message ID.
 * @return The resolution event.
 */
+ (instancetype)legacyReplacedEventWithMessageID:(NSString *)messageID
                                   replacementID:(NSString *)replacementID;

/**
 * Creates a direct open in-app resolution event.
 *
 * @param messageID The message ID.
 * @return The resolution event.
 */
+ (instancetype)legacyDirectOpenEventWithMessageID:(NSString *)messageID;

/**
 * Creates a resolution event.
 *
 * @param messageID The message ID.
 * @param message The in-app message.
 * @param resolution The in-app message resolution.
 * @param displayTime The amount of time the message was displayed.
 * @return The resolution event.
 */
+ (instancetype)eventWithMessageID:(NSString *)messageID
                           message:(UAInAppMessage *)message
                        resolution:(UAInAppMessageResolution *)resolution
                       displayTime:(NSTimeInterval)displayTime;

@end

NS_ASSUME_NONNULL_END
