//
//  ABFBeaconRegion.h
//  iBeacon
//
//  Created by ACCESS Co., Ltd. on 2014/03/02.
//  Copyright (c) 2014 ACCESS Co., Ltd. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface ABFBeaconRegion : CLBeaconRegion
@property (nonatomic) BOOL isMonitoring;
@property (nonatomic) BOOL isRanging;
@property (nonatomic) BOOL rangingEnabled;
@property (nonatomic) BOOL hasEntered;
@property (nonatomic) int failCount;
@property (nonatomic) NSArray *beacons;
@property (nonatomic) BOOL isError5;
- (void)initStatus;
@end
