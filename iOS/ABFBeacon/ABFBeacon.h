//
//  ABFBeacon.h
//  iBeacon
//
//  Created by ACCESS Co., Ltd. on 2014/02/28.
//  Copyright (c) 2014 ACCESS Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;
@import CoreBluetooth;
#import "ABFBeaconRegion.h"

@protocol ABFBeaconDelegate <NSObject>
@optional
- (void)didUpdatePeripheralState:(CBPeripheralManagerState)state;
- (void)didUpdateAuthorizationStatus:(CLAuthorizationStatus)status;
- (void)didRangeBeacons:(ABFBeaconRegion *)region;
- (void)didUpdateRegionEnterOrExit:(ABFBeaconRegion *)region;
@end

@interface ABFBeacon : NSObject <CBPeripheralManagerDelegate, CLLocationManagerDelegate>
@property (nonatomic, weak) id<ABFBeaconDelegate> delegate;

@property (nonatomic) BOOL notifyZeroRSSIRegion;
@property (nonatomic) BOOL notifyUnder20RSSIRegion;
@property (nonatomic) BOOL loggingEnabled;

+ (ABFBeacon *)sharedManager;

- (void)startMonitoring;
- (void)stopMonitoring;
- (void)startRegionWithUUIDList:(NSArray *)UUIDList rangingEnabled:(BOOL)rangingEnabled;
- (void)stopRegionWithClearingUUIDList;
@end
