/*
 * AppDelegate+LaunchMyApp - Category to capture URL on cold start
 *
 * This category swizzles the AppDelegate to capture incoming URLs
 * BEFORE plugins are initialized, ensuring cold start URLs are stored.
 *
 * Copyright (c) 2024 Mobilozophy, LLC
 * MIT License
 */

#import "AppDelegate.h"

@interface AppDelegate (LaunchMyApp)

@end
