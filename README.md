# ABFBeacon

ACCESS Beacon Framework Library is wrapper for iBeacon API.

# How to use it

#### Podfile

To integrate ABFBeacon into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, '7.1'

pod 'ABFBeacon', :git => 'https://github.com/access-company/ABFBeacon', :tag => '1.0.0'
```

Then, run the following command:

```bash
$ pod install
```

#### Installation to your project

Add iOS/ABFBeacon files to your project

* ABFBeacon.h
* ABFBeacon.m
* ABFBeaconRegion.h
* ABFBeaconRegion.m

Then

```
#import "ABFBeacon.h"
```

include all of necessary classes.

```
ABFBeacon *beacon = [ABFBeacon sharedManager];
```

will instanciate ABFBeacon singleton.

```
[beacon registerRegion:@"E02CC25E-0049-4185-832C-3A65DB755D01" identifier:@"ACCESS"];
[beacon startMonitoring];
```

Register specified Region and start monitoring on it.
You might need to inherit ABFBeaconDelegate to set delegation.

```
@interface MyClass : NSObject<ABFBeaconDelegate>
```

Here are list of delegates defined in ABFBeaconDelegate.

```
@protocol ABFBeaconDelegate <NSObject>
@optional
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
- (void)didUpdatePeripheralState:(CBManagerState)state;
#else
- (void)didUpdatePeripheralState:(CBPeripheralManagerState)state;
#endif
- (void)didUpdateAuthorizationStatus:(CLAuthorizationStatus)status;
- (void)didRangeBeacons:(ABFBeaconRegion *)region;
- (void)didUpdateRegionEnterOrExit:(ABFBeaconRegion *)region;
@end
```

# Licensing

ABFBeacon is distributed under MIT License.
