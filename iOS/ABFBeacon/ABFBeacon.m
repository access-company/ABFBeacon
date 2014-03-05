//
//  ABFBeacon.m
//  iBeacon
//
//  Created by ACCESS Co., Ltd. on 2014/02/28.
//  Copyright (c) 2014 ACCESS Co., Ltd. All rights reserved.
//

#import "ABFBeacon.h"

@interface ABFBeacon ()
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, strong) NSMutableArray *regions;
@property (nonatomic) BOOL monitoringEnabled;
@end

@implementation ABFBeacon

#pragma mark - Singleton

+ (ABFBeacon *)sharedManager
{
    static ABFBeacon *sharedSingleton;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedSingleton = [[ABFBeacon alloc] initSharedInstance];
    });

    return sharedSingleton;
}

- (id)initSharedInstance
{
    self = [super init];
    if (self) {
        // Allocate peripheral manager.
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
        
        // Allocate location manager.
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;

        // Initialization of ABFBeacon singleton.
        _regions = [@[] mutableCopy];
        
        // Do not notify zero RSSI value by default.
        _notifyZeroRSSIRegion = NO;
        
        // Do not notify under 20 RSSI value by default.
        _notifyUnder20RSSIRegion = NO;
        
        // Disable logggin.
        _loggingEnabled = NO;
        
        //_monitoringStatus = kESBeaconMonitoringStatusDisabled;
        //_monitoringEnabled = NO;
        //_isMonitoring = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - Local notification

- (void)applicationDidBecomeActive
{
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateRegionState:) userInfo:nil repeats:NO];
}

- (void)updateRegionState:(NSTimer *)timer
{
    for (ABFBeaconRegion *region in self.regions) {
        if (region.isMonitoring) {
            [_locationManager requestStateForRegion:region];
        }
    }
}

#pragma mark - ABFBeacon Monitoring management

- (void)startMonitoring
{
    _monitoringEnabled = YES;
    [self enableMonitoring];
}

- (void)stopMonitoring
{
    _monitoringEnabled = NO;
    [self disableMonitoring];
}

- (BOOL)isMonitoringCapable
{
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]] &&
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized &&
        _peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
        return YES;
    } else {
        return NO;
    }
}

- (void)updateMonitoring
{
    if ([self isMonitoringCapable]) {
        [self enableMonitoring];
    } else {
        [self disableMonitoring];
    }
}

- (void)enableMonitoring
{
    if (! self.monitoringEnabled) {
        return;
    }

    if (! [self isMonitoringCapable]) {
        return;
    }

    for (ABFBeaconRegion *region in self.regions) {
        if (!region.isMonitoring) {
            [_locationManager startMonitoringForRegion:region];
            region.isMonitoring = YES;
        }
    }
}

- (void)disableMonitoring
{
    for (ABFBeaconRegion *region in self.regions) {
        [self disableMonitoringForRegion:region];
    }
}

- (void)disableMonitoringForRegion:(ABFBeaconRegion *)region
{
    [_locationManager stopMonitoringForRegion:region];
    [self stopRanging:region];
    region.isMonitoring = NO;
    if (region.hasEntered) {
        region.hasEntered = NO;
        if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
            [_delegate didUpdateRegionEnterOrExit:region];
        }
    }
}

- (void)startRanging:(ABFBeaconRegion *)region
{
    if (! region.isRanging) {
        if(_loggingEnabled) {
            NSLog(@"startRanging");
        }
        [_locationManager startRangingBeaconsInRegion:region];
        region.isRanging = YES;
    }
}

- (void)stopRanging:(ABFBeaconRegion *)region
{
    if (region.isRanging) {
        if (_loggingEnabled) {
            NSLog(@"stopRanging");
        }
        [_locationManager stopRangingBeaconsInRegion:region];
        region.beacons = nil;
        region.isRanging = NO;
    }
}

- (ABFBeaconRegion *)lookupRegion:(CLBeaconRegion *)region
{
    for (ABFBeaconRegion *beaconRegion in _regions) {
        if ([beaconRegion.proximityUUID.UUIDString isEqualToString:region.proximityUUID.UUIDString] &&
            [beaconRegion.identifier isEqualToString:region.identifier] &&
            beaconRegion.major == region.major &&
            beaconRegion.minor == region.minor) {
            return beaconRegion;
        }
    }
    return nil;
}

#pragma mark - ABFBeacon Region management

#define ABFBeaconRegionMax 20

- (void)regionAdd:(ABFBeaconRegion *)region
{
    if (_loggingEnabled) {
        NSLog(@"Region Regstered: %@", region);
    }
    if (region) {
        [region initStatus];
        [self.regions addObject:region];
    }
}

- (ABFBeaconRegion *)registerRegion:(NSString *)UUIDString identifier:(NSString *)identifier
{
    if ([self.regions count] >= ABFBeaconRegionMax) {
        return nil;
    }
    ABFBeaconRegion *region = [[ABFBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] identifier:identifier];
    [self regionAdd:region];
    return region;
}

- (ABFBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major identifier:(NSString *)identifier
{
    if ([self.regions count] >= ABFBeaconRegionMax) {
        return nil;
    }
    ABFBeaconRegion *region = [[ABFBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] major:major identifier:identifier];
    [self regionAdd:region];
    return region;
}

- (ABFBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier
{
    if ([self.regions count] >= ABFBeaconRegionMax) {
        return nil;
    }
    ABFBeaconRegion *region = [[ABFBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] major:major minor:minor identifier:identifier];
    [self regionAdd:region];
    return region;
}

- (void)startRegionWithUUIDList:(NSArray *)UUIDList rangingEnabled:(BOOL)rangingEnabled
{
    [self stopRegionWithClearingUUIDList];
    
    int index = 0;
    for (NSString *UUIDString in UUIDList) {
        NSString *identifier = [NSString stringWithFormat:@"Identifier%d", ++index];
        ABFBeaconRegion *region = [self registerRegion:UUIDString identifier:identifier];
        if (region) {
            region.rangingEnabled = rangingEnabled;
        }
    }

    [self startMonitoring];
}

- (void)stopRegionWithClearingUUIDList
{
    [self stopMonitoring];
    [self.regions removeAllObjects];
}

#pragma mark - CBPeripheralManagerDelegate

- (NSString *)peripheralStateString:(CBPeripheralManagerState)state
{
    switch (state) {
        case CBPeripheralManagerStatePoweredOn:
            return @"On";
        case CBPeripheralManagerStatePoweredOff:
            return @"Off";
        case CBPeripheralManagerStateResetting:
            return @"Resetting";
        case CBPeripheralManagerStateUnauthorized:
            return @"Unauthorized";
        case CBPeripheralManagerStateUnknown:
            return @"Unknown";
        case CBPeripheralManagerStateUnsupported:
            return @"Unsupported";
    }
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    if (_loggingEnabled) {
        NSLog(@"peripheralManagerDidUpdateState: %@", [self peripheralStateString:peripheral.state]);
    }

    [self updateMonitoring];

    if ([_delegate respondsToSelector:@selector(didUpdatePeripheralState:)]) {
        [_delegate didUpdatePeripheralState:peripheral.state];
    }
}

#pragma mark CLLocationManagerDelegate (Responding to Authorization Changes)
- (NSString *)locationAuthorizationStatusString:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            return @"Not determined";
        case kCLAuthorizationStatusRestricted:
            return @"Restricted";
        case kCLAuthorizationStatusDenied:
            return @"Denied";
        case kCLAuthorizationStatusAuthorized:
            return @"Authorized";
    }
    return @"";
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (_loggingEnabled) {
        NSLog(@"didChangeAuthorizationStatus:%@", [self locationAuthorizationStatusString:status]);
    }
    
    [self updateMonitoring];

    if ([_delegate respondsToSelector:@selector(didUpdateAuthorizationStatus:)]) {
        [_delegate didUpdateAuthorizationStatus:status];
    }
}

#pragma mark CLLocationManagerDelegate - Region

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    if (_loggingEnabled) {
        NSLog(@"didStartMonitoringForRegion:%@", region.identifier);
    }
    
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        ABFBeaconRegion *esBeacon = [self lookupRegion:(CLBeaconRegion *)region];
        if (esBeacon) {
            esBeacon.failCount = 0;
        }
    }
    [self.locationManager requestStateForRegion:region];
}

@end
