//
//  ABFBeaconRegion.m
//  iBeacon
//
//  Created by ACCESS Co., Ltd. on 2014/03/02.
//  Copyright (c) 2014 ACCESS Co., Ltd. All rights reserved.
//

#import "ABFBeaconRegion.h"

@interface ABFBeaconRegion()
@property (nonatomic) BOOL enteredFlagRestored;
@end

@implementation ABFBeaconRegion
@synthesize hasEntered = _hasEntered;

- (NSString *)generateKey
{
    return [NSString stringWithFormat:@"ABFBeaconRegion:%@", self.identifier];
}

- (void)initStatus
{
    _isMonitoring = NO;
    _isRanging = NO;
    _rangingEnabled = NO;
    _hasEntered = NO;
    _beacons = nil;
    _failCount = 0;
    _enteredFlagRestored = NO;
}

- (void)setHasEntered:(BOOL)hasEntered
{
    _hasEntered = hasEntered;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (hasEntered) {
        [ud setBool:YES forKey:[self generateKey]];
    } else {
        [ud removeObjectForKey:[self generateKey]];
    }
    [ud synchronize];
}

- (BOOL)hasEntered
{
    if (!self.enteredFlagRestored) {
        _hasEntered = [[NSUserDefaults standardUserDefaults] boolForKey:[self generateKey]];
        self.enteredFlagRestored = YES;
    }
    
    return _hasEntered;
}
@end
