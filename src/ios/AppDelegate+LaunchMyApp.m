/*
 * AppDelegate+LaunchMyApp - Category to capture URL on cold start
 *
 * This category swizzles both AppDelegate and SceneDelegate to capture
 * incoming URLs BEFORE plugins are initialized.
 *
 * iOS 13+ with Scenes: URL comes via scene:willConnectToSession:options: (cold)
 *                      or scene:openURLContexts: (warm)
 * iOS 12 and earlier:  URL comes via application:openURL:options:
 *
 * Copyright (c) 2024 Mobilozophy, LLC
 * MIT License
 */

#import "AppDelegate+LaunchMyApp.h"
#import <objc/runtime.h>

static NSString* const kLastUrlKey = @"LaunchMyApp_lastUrl";

// Helper function to store URL
static void storeURL(NSURL *url, NSString *source) {
    if (!url) return;

    NSLog(@"[LaunchMyApp] %@ - Storing URL: %@", source, url.absoluteString);
    [[NSUserDefaults standardUserDefaults] setObject:url.absoluteString forKey:kLastUrlKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // DEBUG: Show native alert
    dispatch_async(dispatch_get_main_queue(), ^{
        // Small delay to ensure UI is ready
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:@"[LaunchMyApp Debug]"
                message:[NSString stringWithFormat:@"%@\n\nURL: %@", source, url.absoluteString]
                preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

            UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            if (rootVC) {
                [rootVC presentViewController:alert animated:YES completion:nil];
            }
        });
    });
}

// Helper function to swizzle a method on any class
static void swizzleMethodOnClass(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    if (!swizzledMethod) {
        NSLog(@"[LaunchMyApp] Swizzled method not found for %@", NSStringFromSelector(swizzledSelector));
        return;
    }

    if (!originalMethod) {
        // Original doesn't exist, just add our method as the original
        class_addMethod(class,
                       originalSelector,
                       method_getImplementation(swizzledMethod),
                       method_getTypeEncoding(swizzledMethod));
        NSLog(@"[LaunchMyApp] Added %@ to %@", NSStringFromSelector(originalSelector), NSStringFromClass(class));
        return;
    }

    BOOL didAdd = class_addMethod(class,
                                  originalSelector,
                                  method_getImplementation(swizzledMethod),
                                  method_getTypeEncoding(swizzledMethod));

    if (didAdd) {
        class_replaceMethod(class,
                           swizzledSelector,
                           method_getImplementation(originalMethod),
                           method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    NSLog(@"[LaunchMyApp] Swizzled %@ on %@", NSStringFromSelector(originalSelector), NSStringFromClass(class));
}

@implementation AppDelegate (LaunchMyApp)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[LaunchMyApp] AppDelegate category loading...");

        // Swizzle AppDelegate for iOS 12 and earlier (and some edge cases)
        swizzleMethodOnClass([self class],
                            @selector(application:openURL:options:),
                            @selector(launchMyApp_application:openURL:options:));

        // For iOS 13+, swizzle CDVSceneDelegate IMMEDIATELY (before it's used)
        // CDVSceneDelegate should already be loaded since it's part of Cordova
        Class sceneClass = NSClassFromString(@"CDVSceneDelegate");
        if (sceneClass) {
            NSLog(@"[LaunchMyApp] Found CDVSceneDelegate in +load, swizzling immediately");
            [self swizzleSceneDelegateClass:sceneClass];
        } else {
            NSLog(@"[LaunchMyApp] CDVSceneDelegate not found in +load, will try later");
            // Fallback: try again on main queue (for warm start cases)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self swizzleSceneDelegateMethods];
            });
        }

        NSLog(@"[LaunchMyApp] AppDelegate category loaded - swizzling complete");
    });
}

+ (void)swizzleSceneDelegateClass:(Class)sceneClass {
    NSLog(@"[LaunchMyApp] Swizzling scene delegate class: %@", NSStringFromClass(sceneClass));

    // Swizzle scene:openURLContexts: for warm start
    SEL openURLSel = @selector(scene:openURLContexts:);
    SEL swizzledOpenURLSel = @selector(launchMyApp_scene:openURLContexts:);
    Method swizzledOpenURL = class_getInstanceMethod([self class], swizzledOpenURLSel);
    if (swizzledOpenURL) {
        class_addMethod(sceneClass, swizzledOpenURLSel,
                       method_getImplementation(swizzledOpenURL),
                       method_getTypeEncoding(swizzledOpenURL));
        swizzleMethodOnClass(sceneClass, openURLSel, swizzledOpenURLSel);
    }

    // Swizzle scene:willConnectToSession:options: for cold start
    SEL willConnectSel = @selector(scene:willConnectToSession:options:);
    SEL swizzledWillConnectSel = @selector(launchMyApp_scene:willConnectToSession:options:);
    Method swizzledWillConnect = class_getInstanceMethod([self class], swizzledWillConnectSel);
    if (swizzledWillConnect) {
        class_addMethod(sceneClass, swizzledWillConnectSel,
                       method_getImplementation(swizzledWillConnect),
                       method_getTypeEncoding(swizzledWillConnect));
        swizzleMethodOnClass(sceneClass, willConnectSel, swizzledWillConnectSel);
    }
}

+ (void)swizzleSceneDelegateMethods {
    // Find the scene delegate class - Cordova typically uses its own
    Class sceneClass = NSClassFromString(@"CDVSceneDelegate");
    if (!sceneClass) {
        // Try getting it from the scene configuration
        NSArray *scenes = [UIApplication sharedApplication].connectedScenes.allObjects;
        for (UIScene *scene in scenes) {
            if (scene.delegate) {
                sceneClass = [scene.delegate class];
                break;
            }
        }
    }

    if (sceneClass) {
        [self swizzleSceneDelegateClass:sceneClass];
    } else {
        NSLog(@"[LaunchMyApp] No scene delegate class found");
    }
}

#pragma mark - Swizzled Methods

- (BOOL)launchMyApp_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    NSLog(@"[LaunchMyApp] application:openURL:options: called");
    storeURL(url, @"AppDelegate openURL");

    // Call original
    return [self launchMyApp_application:app openURL:url options:options];
}

- (void)launchMyApp_scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    NSLog(@"[LaunchMyApp] scene:openURLContexts: called with %lu contexts", (unsigned long)URLContexts.count);

    for (UIOpenURLContext *context in URLContexts) {
        storeURL(context.URL, @"SceneDelegate openURLContexts (warm)");
    }

    // Call original if it exists
    if ([self respondsToSelector:@selector(launchMyApp_scene:openURLContexts:)]) {
        [self launchMyApp_scene:scene openURLContexts:URLContexts];
    }
}

- (void)launchMyApp_scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    NSLog(@"[LaunchMyApp] scene:willConnectToSession:options: called");

    // Check for URLs in connectionOptions (cold start)
    if (connectionOptions.URLContexts.count > 0) {
        NSLog(@"[LaunchMyApp] Found %lu URL contexts in connectionOptions", (unsigned long)connectionOptions.URLContexts.count);
        for (UIOpenURLContext *context in connectionOptions.URLContexts) {
            storeURL(context.URL, @"SceneDelegate willConnect (cold)");
        }
    } else {
        NSLog(@"[LaunchMyApp] No URL contexts in connectionOptions");
    }

    // Call original
    if ([self respondsToSelector:@selector(launchMyApp_scene:willConnectToSession:options:)]) {
        [self launchMyApp_scene:scene willConnectToSession:session options:connectionOptions];
    }
}

@end
