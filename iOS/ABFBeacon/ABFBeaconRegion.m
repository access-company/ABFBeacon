//
//  ABFBeaconRegion.m
//  iBeacon
//
//  Created by ACCESS Co., Ltd. on 2014/03/02.
//  Copyright (c) 2014 ACCESS Co., Ltd. All rights reserved.
//

#import "ABFBeaconRegion.h"

@implementation ABFBeaconRegion

- (void)initStatus
{
    _isMonitoring = NO;
    _isRanging = NO;
    _rangingEnabled = NO;
    _hasEntered = NO;
    _beacons = nil;
    _failCount = 0;
}

@end
