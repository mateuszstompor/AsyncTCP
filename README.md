# AsyncTCP
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<p align="center">
  <img src="./Assets/icon.png" width="45%">
</p>

## About

A tiny library easing TCP connections handling. Provides a set of classes for the user to connect to a remote server as a client and is able to host a server on its own.

Non-blocking and asynchronous, uses delegation to notify about incoming data packets, connection state change, etc. Gives you a choice which dispatch queue you'd like to choose to receive the notifications. 

All components are loosly coupled, as a result the code is testable and **tested**.


# Examples
### Setting up a server
First of all define server's boot parameters
```objective-c
struct ServerConfiguration configuration;
// Port is a number in range from 0 to 65535
configuration.port = 47851;
// Chunk size is a buffer size
configuration.chunkSize = 36;
// Time of inactivity after which client's connection is going to be closed
configuration.connectionTimeout = 5;
// Number of clients allowed to connect
configuration.maximalConnectionsCount = 1;
// Interval between server's main loop evaluations. Adjust depending on your network speed and device's resources utilization
configuration.eventLoopMicrosecondsDelay = 20;
```
Create a server with this specific configuration. By default all notification will be passed to the main dispatch queue.
```objective-c
NSObject<ServerHandle> * asyncServer = [[Server alloc] initWithConfiguratoin:configuration];
```
Notifications will be send only if the delegate of the server is set. Otherwise connections won't be accepted and data received. To receive notifications implement `ServerDelegate` protocol.
**Interface**
```objective-c
@interface ServerHandler: NSObject<ServerDelegate>
@end
```
**Implementation**
```objective-c
@implementation ServerHandler
-(void)newClientHasConnected: (Connection*) connection {
    // Handle the connection here somehow
}
@end
```
One additional step to make is to implement `ConnectionDelegate` protocol. It is an interface which lets you receive a notification when data is received or connection's state updated.
**Interface**
```objective-c
@interface ConnectionHandler: NSObject<ConnectionDelegate>
@end
```
**Implementation**
```objective-c
@implementation ConnectionHandler
-(void)connection:(NSObject<ConnectionHandle> *)connection chunkHasArrived:(NSData *)data {
    // Parse the data or pass it through 
}
-(void)connection:(NSObject<ConnectionHandle> *)connection stateHasChangedTo:(ConnectionState)state {
    // Ivoked when a client disconnected or the connection hung 
}
@end
```