//
//  ABFBeacon.h
//  iBeacon
//
//  Created by ACCESS Co., Ltd. on 2014/02/28.
//  Copyright (c) 2014 ACCESS Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "ABFBeaconRegion.h"

@protocol ABFBeaconDelegate <NSObject>
@optional
- (void)didUpdatePeripheralState:(CBPeripheralManagerState)state;
- (void)didUpdateAuthorizationStatus:(CLAuthorizationStatus)status;
- (void)didRangeBeacons:(ABFBeaconRegion *)region;
- (void)didUpdateRegionEnterOrExit:(ABFBeaconRegion *)region;
@end

#define ABFBeaconDefaultRegionMaxCount            20
#define ABFBeaconDefaultMaxFailCount               3

@interface ABFBeacon : NSObject <CBPeripheralManagerDelegate, CLLocationManagerDelegate>
@property (nonatomic, strong) NSMutableArray *regions;
@property (nonatomic) BOOL monitoringEnabled;

@property (nonatomic, weak) id<ABFBeaconDelegate> delegate;
@property (nonatomic) BOOL notifyZeroRSSIRegion;
@property (nonatomic) BOOL notifyUnder20RSSIRegion;
@property (nonatomic) BOOL loggingEnabled;
@property (nonatomic) int regionMaxCount;
@property (nonatomic) int maxFailCount;

+ (ABFBeacon *)sharedManager;

- (void)startMonitoring;
- (void)stopMonitoring;
- (ABFBeaconRegion *)registerRegion:(NSString *)UUIDString identifier:(NSString *)identifier;
- (ABFBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major identifier:(NSString *)identifier;
- (ABFBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier;
- (void)startRegionWithUUIDList:(NSArray *)UUIDList rangingEnabled:(BOOL)rangingEnabled;
- (void)stopRegionWithClearingUUIDList;
- (void)requestUpdateForStatus;
- (BOOL)isMonitoringCapable;
@end
