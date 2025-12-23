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

#import <Cordova/CDVPlugin.h>

@interface LaunchMyApp : CDVPlugin

// Get the last URL that launched the app (does not clear)
- (void)getLastUrl:(CDVInvokedUrlCommand*)command;

// Get the last URL and clear it (typical use case)
- (void)getLastUrlAndClear:(CDVInvokedUrlCommand*)command;

// Clear the stored URL without reading
- (void)clearLastUrl:(CDVInvokedUrlCommand*)command;

@end
