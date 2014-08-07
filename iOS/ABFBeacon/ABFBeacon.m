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

- (instancetype)initSharedInstance
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
        
        // Set maximum number of monitoring region.
        _regionMaxCount = ABFBeaconDefaultRegionMaxCount;

        // Max region fail count set to default value.
        _maxFailCount = ABFBeaconDefaultMaxFailCount;
        
        // Monitoring status.
        _monitoringEnabled = NO;

        /* This may cause a issue of kCLErrorDomain error 5, commenting out for now.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        */
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - Local notification

- (void)applicationDidBecomeActive
{
    [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateRegionStateTimer:) userInfo:nil repeats:NO];
}

- (void)updateRegionStateTimer:(NSTimer *)timer
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
    if (![CLBeaconRegion class]) {
        return NO;
    }

    if (![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        return NO;
    }
    if (_peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        return NO;
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        return NO;
    }
    return YES;
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
    if (!self.monitoringEnabled) {
        return;
    }

    if (![self isMonitoringCapable]) {
        return;
    }

    for (ABFBeaconRegion *region in self.regions) {
        if (!region.isMonitoring) {
            [self enableMonitoringForRegion:region];
        }
    }
}

- (void)enableMonitoringForRegion:(ABFBeaconRegion *)region
{
    if (!self.monitoringEnabled) {
        return;
    }
    
    if (![self isMonitoringCapable]) {
        return;
    }
    
    if (region.isMonitoring) {
        return;
    }
    
    [_locationManager startMonitoringForRegion:region];
    region.isMonitoring = YES;
}

- (void)enableMonitoringForRegionTimer:(NSTimer *)timer
{
    [self enableMonitoringForRegion:(ABFBeaconRegion *)timer.userInfo];
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
            NSLog(@"ABF startRanging:%@", region.identifier);
        }
        [_locationManager startRangingBeaconsInRegion:region];
        region.isRanging = YES;
    }
}

- (void)stopRanging:(ABFBeaconRegion *)region
{
    if (region.isRanging) {
        if (_loggingEnabled) {
            NSLog(@"ABF stopRanging:%@", region.identifier);
        }
        [_locationManager stopRangingBeaconsInRegion:region];
        region.beacons = nil;
        region.isRanging = NO;
    }
}

- (void)requestUpdateForStatus
{
    if ([_delegate respondsToSelector:@selector(didUpdatePeripheralState:)]) {
        [_delegate didUpdatePeripheralState:self.peripheralManager.state];
    }
    if ([_delegate respondsToSelector:@selector(didUpdateAuthorizationStatus:)]) {
        [_delegate didUpdateAuthorizationStatus:[CLLocationManager authorizationStatus]];
    }
}

#pragma mark - ABFBeacon Region management

- (void)regionAdd:(ABFBeaconRegion *)region
{
    if (_loggingEnabled) {
        NSLog(@"ABF Region Registered: %@", region);
    }
    if (region) {
        [region initStatus];
        [self.regions addObject:region];
        [self enableMonitoringForRegion:region];
    }
}

- (ABFBeaconRegion *)lookupRegion:(CLBeaconRegion *)region
{
    for (ABFBeaconRegion *beaconRegion in _regions) {
        if (![beaconRegion.proximityUUID.UUIDString isEqualToString:region.proximityUUID.UUIDString]) {
            continue;
        }
        if (![beaconRegion.identifier isEqualToString:region.identifier]) {
            continue;
        }
        if (!beaconRegion.major) {
            if (beaconRegion.major != region.major) {
                continue;
            }
        }
        else {
            if (![beaconRegion.major isEqualToNumber:region.major]) {
                continue;
            }
        }
        if (!beaconRegion.minor) {
            if (beaconRegion.minor != region.minor) {
                continue;
            }
        }
        else {
            if (![beaconRegion.minor isEqualToNumber:region.minor]) {
                continue;
            }
        }
        
        return beaconRegion;
    }
    return nil;
}

- (ABFBeaconRegion *)registerRegion:(NSString *)UUIDString identifier:(NSString *)identifier
{
    if ([self.regions count] >= _regionMaxCount) {
        return nil;
    }
    ABFBeaconRegion *region = [[ABFBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] identifier:identifier];
    [self regionAdd:region];
    return region;
}

- (ABFBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major identifier:(NSString *)identifier
{
    if ([self.regions count] >= _regionMaxCount) {
        return nil;
    }
    ABFBeaconRegion *region = [[ABFBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUIDString] major:major identifier:identifier];
    [self regionAdd:region];
    return region;
}

- (ABFBeaconRegion *)registerRegion:(NSString *)UUIDString major:(CLBeaconMajorValue)major minor:(CLBeaconMinorValue)minor identifier:(NSString *)identifier
{
    if ([self.regions count] >= _regionMaxCount) {
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

- (void)enterRegion:(CLBeaconRegion *)region
{
    if (_loggingEnabled) {
        NSLog(@"ABF enterRegion:%@", region.identifier);
    }
    
    // Lookup BeaconRegion.
    ABFBeaconRegion *beaconRegion = [self lookupRegion:region];
    if (! beaconRegion)
        return;
    
    // Already in the region.
    if (beaconRegion.hasEntered)
        return;
    
    // When ranging is enabled, start ranging.
    if (beaconRegion.rangingEnabled)
        [self startRanging:beaconRegion];
    
    // Mark as entered.
    beaconRegion.hasEntered = YES;
    if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
        [_delegate didUpdateRegionEnterOrExit:beaconRegion];
    }
}

- (void)exitRegion:(CLBeaconRegion *)region
{
    if (_loggingEnabled) {
        NSLog(@"ABF exitRegion:%@", region.identifier);
    }
    
    ABFBeaconRegion *beaconRegion = [self lookupRegion:region];
    if (! beaconRegion)
        return;
    
    if (! beaconRegion.hasEntered)
        return;
    
    if (beaconRegion.rangingEnabled)
        [self stopRanging:beaconRegion];
    
    beaconRegion.hasEntered = NO;
    if ([_delegate respondsToSelector:@selector(didUpdateRegionEnterOrExit:)]) {
        [_delegate didUpdateRegionEnterOrExit:beaconRegion];
    }
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
        NSLog(@"ABF peripheralManagerDidUpdateState: %@", [self peripheralStateString:peripheral.state]);
    }

    [self updateMonitoring];

    if ([_delegate respondsToSelector:@selector(didUpdatePeripheralState:)]) {
        [_delegate didUpdatePeripheralState:peripheral.state];
    }
}

#pragma mark CLLocationManagerDelegate - Authorization
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
        NSLog(@"ABF didChangeAuthorizationStatus:%@", [self locationAuthorizationStatusString:status]);
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
        NSLog(@"ABF didStartMonitoringForRegion:%@", region.identifier);
    }
    
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        ABFBeaconRegion *esBeacon = [self lookupRegion:(CLBeaconRegion *)region];
        if (esBeacon) {
            esBeacon.failCount = 0;
            esBeacon.isError5 = NO;
        }
    }
    [self.locationManager requestStateForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self enterRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [self exitRegion:(CLBeaconRegion *)region];
    }
}

- (NSString *)regionStateString:(CLRegionState)state
{
    switch (state) {
        case CLRegionStateInside:
            return @"inside";
        case CLRegionStateOutside:
            return @"outside";
        case CLRegionStateUnknown:
            return @"unknown";
    }
    return @"";
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    if (_loggingEnabled) {
        NSLog(@"ABF didDetermineState:%@(%@)", [self regionStateString:state], region.identifier);
    }
    
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        switch (state) {
            case CLRegionStateInside:
                [self enterRegion:(CLBeaconRegion *)region];
                break;
            case CLRegionStateOutside:
            case CLRegionStateUnknown:
                [self exitRegion:(CLBeaconRegion *)region];
                break;
            default:
                break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    if (_loggingEnabled) {
        NSLog(@"ABF monitoringDidFailForRegion:%@(%@)", region.identifier, error);
    }
    
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        ABFBeaconRegion *beaconRegion = [self lookupRegion:(CLBeaconRegion *)region];
        if (! beaconRegion)
            return;
        
        [self disableMonitoringForRegion:beaconRegion];
        
        if (error.code == kCLErrorRegionMonitoringFailure) {
            beaconRegion.isError5 = YES;
        }
        
        if (beaconRegion.failCount < _maxFailCount) {
            beaconRegion.failCount++;
            [NSTimer scheduledTimerWithTimeInterval:1.f
                                             target:self
                                           selector:@selector(enableMonitoringForRegionTimer:)
                                           userInfo:beaconRegion
                                            repeats:NO];
        }
    } else if ([region isKindOfClass:[CLCircularRegion class]]) {
        if (error.code == kCLErrorRegionMonitoringFailure) {
            NSLog(@"ABF CLCircularRegion error5: %@", region.identifier);
        }
    }
}

#pragma mark - CLLocationManagerDelegate - Ranging

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if (_loggingEnabled) {
        NSLog(@"ABF didRangeBeacons:%@", region.identifier);
    }
    
    ABFBeaconRegion *beaconRegion = [self lookupRegion:region];
    if (!beaconRegion) {
        return;
    }
    
    beaconRegion.beacons = beacons;
    
    if ([_delegate respondsToSelector:@selector(didRangeBeacons:)]) {
        [_delegate didRangeBeacons:beaconRegion];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    if (_loggingEnabled) {
        NSLog(@"ABF rangingBeaconsDidFailForRegion:%@(%@)", region.identifier, error);
    }
    
    ABFBeaconRegion *beaconRegion = [self lookupRegion:region];
    if (!beaconRegion) {
        return;
    }
    
    [self stopRanging:beaconRegion];
}

@end
