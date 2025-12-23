/*
 * LaunchMyApp - Custom URL Scheme Plugin for Cordova iOS
 *
 * Provides methods to retrieve the launch URL for cold start scenarios
 * where handleOpenURL may not be called reliably (e.g., remote content apps).
 *
 * Copyright (c) 2024 Mobilozophy, LLC
 * Based on Custom-URL-scheme by Eddy Verbruggen
 * MIT License
 */

#import "LaunchMyApp.h"
#import <Cordova/CDVPlugin.h>

static NSString* const kLastUrlKey = @"LaunchMyApp_lastUrl";

@implementation LaunchMyApp

- (void)pluginInitialize {
    // Listen for URL open notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleOpenURLNotification:)
                                                 name:CDVPluginHandleOpenURLNotification
                                               object:nil];

    NSLog(@"[LaunchMyApp] Plugin initialized, listening for URL notifications");
}

- (void)handleOpenURLNotification:(NSNotification*)notification {
    NSURL* url = [notification object];

    if (url) {
        NSString* urlString = [url absoluteString];
        NSLog(@"[LaunchMyApp] Storing launch URL: %@", urlString);

        // Store in NSUserDefaults for later retrieval
        [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:kLastUrlKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)getLastUrl:(CDVInvokedUrlCommand*)command {
    NSString* urlString = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUrlKey];

    NSLog(@"[LaunchMyApp] getLastUrl called, returning: %@", urlString ?: @"(nil)");

    CDVPluginResult* result;
    if (urlString) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:urlString];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:nil];
    }

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)getLastUrlAndClear:(CDVInvokedUrlCommand*)command {
    NSString* urlString = [[NSUserDefaults standardUserDefaults] objectForKey:kLastUrlKey];

    NSLog(@"[LaunchMyApp] getLastUrlAndClear called, returning: %@", urlString ?: @"(nil)");

    // Clear after reading
    if (urlString) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastUrlKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"[LaunchMyApp] URL cleared from storage");
    }

    CDVPluginResult* result;
    if (urlString) {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:urlString];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:nil];
    }

    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)clearLastUrl:(CDVInvokedUrlCommand*)command {
    NSLog(@"[LaunchMyApp] clearLastUrl called");

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastUrlKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
