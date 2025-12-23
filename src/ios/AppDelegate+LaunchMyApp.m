/*
 * AppDelegate+LaunchMyApp - Category to capture URL on cold start
 *
 * This category swizzles the AppDelegate to capture incoming URLs
 * BEFORE plugins are initialized, ensuring cold start URLs are stored.
 *
 * Copyright (c) 2024 Mobilozophy, LLC
 * MIT License
 */

#import "AppDelegate+LaunchMyApp.h"
#import <objc/runtime.h>

static NSString* const kLastUrlKey = @"LaunchMyApp_lastUrl";

@implementation AppDelegate (LaunchMyApp)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Swizzle application:openURL:options: to capture URLs immediately
        [self swizzleMethod:@selector(application:openURL:options:)
                 withMethod:@selector(launchMyApp_application:openURL:options:)];

        NSLog(@"[LaunchMyApp] AppDelegate category loaded - URL capture swizzled");
    });
}

+ (void)swizzleMethod:(SEL)originalSelector withMethod:(SEL)swizzledSelector {
    Class class = [self class];

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    // If original doesn't exist, add it first
    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class,
                           swizzledSelector,
                           method_getImplementation(originalMethod),
                           method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (BOOL)launchMyApp_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    NSLog(@"[LaunchMyApp] Intercepted URL in AppDelegate: %@", url.absoluteString);

    // Store the URL IMMEDIATELY - before any other processing
    if (url) {
        [[NSUserDefaults standardUserDefaults] setObject:url.absoluteString forKey:kLastUrlKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"[LaunchMyApp] URL stored in NSUserDefaults: %@", url.absoluteString);

        // DEBUG: Show native alert to confirm URL was captured
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:@"[LaunchMyApp Debug]"
                message:[NSString stringWithFormat:@"URL Captured!\n\n%@", url.absoluteString]
                preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction
                actionWithTitle:@"OK"
                style:UIAlertActionStyleDefault
                handler:nil];

            [alert addAction:okAction];

            // Get the root view controller to present the alert
            UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:alert animated:YES completion:nil];
        });
    }

    // Call the original implementation (which will post the notification, etc.)
    return [self launchMyApp_application:app openURL:url options:options];
}

@end
