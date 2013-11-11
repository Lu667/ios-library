
#import "UAActionJSDelegate.h"
#import "UAGlobal.h"

#import "NSJSONSerialization+UAAdditions.h"
#import "NSString+URLEncoding.h"

#import "UAActionRunner.h"

@implementation UAActionJSDelegate

- (UAAction *)actionForEncodedName:(NSString *)name {
    NSString *decodedName = [name urlDecodedStringWithEncoding:NSUTF8StringEncoding];
    if (!decodedName) {
        UA_LDEBUG(@"unable to url decode action name: %@", name);
    }
    UAAction *action = [[UAActionRegistrar shared] registryEntryForName:decodedName].action;
    if (!action) {
        UA_LDEBUG(@"no registry entry found for action name: %@", decodedName);
    } else {
        UA_LDEBUG(@"action name: %@", decodedName);
    }
    return action;
}

- (id)objectForEncodedArguments:(NSString *)arguments {
    NSString *urlDecodedArgs = [arguments urlDecodedStringWithEncoding:NSUTF8StringEncoding];
    if (!urlDecodedArgs) {
        UA_LDEBUG(@"unable to url decode action args: %@", arguments);
        return nil;
    }
    //use NSJSONSerialization directly here, so we can allow the reading of fragments
    id jsonDecodedArgs = [NSJSONSerialization JSONObjectWithData: [urlDecodedArgs dataUsingEncoding:NSUTF8StringEncoding]
                                                          options: NSJSONReadingMutableContainers | NSJSONReadingAllowFragments
                                                            error: nil];
    if (!jsonDecodedArgs) {
        UA_LDEBUG(@"unable to to json decode action args: %@", urlDecodedArgs);
    } else {
        UA_LDEBUG(@"action arguments value: %@", jsonDecodedArgs);
    }
    return jsonDecodedArgs;
}

- (void)runActionWithCallbackID:(NSString *)callbackID
                    withOptions:(NSDictionary *)options
       withCompletionHandler:(UAJavaScriptDelegateCompletionHandler)completionHandler {
    NSArray *keys = [options allKeys];

    if (keys.count) {

        NSString *actionName = [keys objectAtIndex:0];

        UAAction *action = [self actionForEncodedName:actionName];
        NSString *encodedArgumentsValue = [options valueForKey:actionName];
        id decodedArgumentsValue;
        if (encodedArgumentsValue) {
            decodedArgumentsValue = [self objectForEncodedArguments:encodedArgumentsValue];
        }

        //we have enough to work with as long as there's an action to run, and either no encoded args
        //or properly decoded args
        if (action && (decodedArgumentsValue || !encodedArgumentsValue)) {
            UAActionArguments *actionArgs = [UAActionArguments argumentsWithValue:decodedArgumentsValue
                                                                    withSituation:UASituationRichPushAction];
            [UAActionRunner runAction:action withArguments:actionArgs withCompletionHandler:^(UAActionResult *result){
                if (result.error){
                    UA_LDEBUG(@"action %@ completed with an error", actionName);
                    if (callbackID) {
                        NSString *script = [NSString stringWithFormat:@"var err = new Error('%@');UAirship.finishAction(err, null, '%@');", result.error.localizedDescription, callbackID];
                        completionHandler(script);
                    }
                } else {
                    UA_LDEBUG(@"action %@ completed successfully", actionName);
                    if (callbackID) {
                        NSString *resultString;
                        if (result.value) {
                            resultString = [NSJSONSerialization stringWithObject:result.value];
                        }

                        resultString = resultString ?: @"null";
                        NSString *script = [NSString stringWithFormat:@"UAirship.finishAction(null, '%@', '%@');", resultString, callbackID];
                        completionHandler(script);
                    }
                }
            }];
        } else {
            //we'll probably eventually want to pass different kinds of errors
            if (callbackID) {
                NSString *errorString;
                if (!action) {
                    errorString = [NSString stringWithFormat:@"Unable to retrieve action named: %@", actionName];
                } else if (!decodedArgumentsValue) {
                    errorString = [NSString stringWithFormat:@"Error decoding arguments: %@", encodedArgumentsValue];
                }
                NSString *script = [NSString stringWithFormat:@"UAirship.finishAction(new Error('%@'), null, '%@');", errorString, callbackID];
                completionHandler(script);
            }
        }
    } else {
        UA_LDEBUG(@"Unable to parse options");
    }
}

- (void)basicActionWithOptions:(NSDictionary *)options
         withCompletionHandler:(UAJavaScriptDelegateCompletionHandler)completionHandler {
    
    for (NSString *actionName in options) {
        UAAction *action = [self actionForEncodedName:actionName];
        NSString *encodedArgumentsValue = [options objectForKey:actionName];
        NSString *decodedArgumentsValue = [encodedArgumentsValue urlDecodedStringWithEncoding:NSUTF8StringEncoding];

        UAActionArguments *actionArgs = [UAActionArguments argumentsWithValue:decodedArgumentsValue withSituation:UASituationRichPushAction];

        if (action && (!encodedArgumentsValue || decodedArgumentsValue)) {
            [UAActionRunner runAction:action withArguments:actionArgs withCompletionHandler:^(UAActionResult *result){
                if (result.error) {
                    UA_LDEBUG(@"action %@ completed with an error", actionName);
                } else {
                    UA_LDEBUG(@"action %@ completed successfully", actionName);
                }
            }];
        }
    }
}

- (void)callbackArguments:(NSArray *)args
              withOptions:(NSDictionary *)options
    withCompletionHandler:(UAJavaScriptDelegateCompletionHandler)completionHandler {
    UA_LDEBUG(@"internal js delegate arguments: %@ \n options: %@", args, options);

    if (args.count){
        if ([[args objectAtIndex:0] isEqualToString:@"run-action"]) {
            NSString *callbackID;
            if (args.count > 1) {
                callbackID = [args objectAtIndex:1];
            }
            [self runActionWithCallbackID:callbackID
                              withOptions:options
                    withCompletionHandler:completionHandler];
        } else if ([[args objectAtIndex:0] isEqualToString:@"basic-action"]) {
            [self basicActionWithOptions:options withCompletionHandler:completionHandler];
        }
    } else {
        //args not recognized, pass a nil script result
        completionHandler(nil);
    }
}

@end
