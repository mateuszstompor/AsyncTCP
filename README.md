<p align="center">
  <img src="https://github.com/mateuszstompor/AsyncTCP/blob/master/Assets/icon.png?raw=true" width="40%">
</p>
<h1 align="center">AsyncTCP</h1>
<p align="center">    
    <a href="https://cocoapods.org/pods/AsyncTCP">
        <img src="https://img.shields.io/cocoapods/v/AsyncTCP" height="18pt" alt="Cocoapod"/>
    </a>
    <a href="https://codecov.io/gh/mateuszstompor/AsyncTCP">
        <img src="https://codecov.io/gh/mateuszstompor/AsyncTCP/branch/master/graph/badge.svg" height="18pt" alt="Coverage"/>
    </a>
    <a href="https://opensource.org/licenses/MIT">
        <img src="https://img.shields.io/badge/License-MIT-yellow.svg" height="18pt" alt="License"/>
    </a>
    <a href="https://www.travis-ci.org/mateuszstompor/AsyncTCP">
        <img src="https://github.com/mateuszstompor/AsyncTCP/actions/workflows/tests.yml/badge.svg" height="18pt" alt="Build status"/>
    </a>
</p>

## About

A tiny library easing TCP connections handling. Provides a set of classes for the user to connect to a remote server as a client and is able to host a server on its own.

Non-blocking and asynchronous, uses delegation to notify about incoming data packets, connection state change, etc. Gives you a choice which dispatch queue you'd like to choose to receive the notifications. 

All components are loosly coupled, as a result the code is testable and **tested**.


# Examples
### Setting up a server
First of all define server's boot parameters
```objective-c
ServerConfiguration * configuration = [[ServerConfiguration alloc] initWithPort:57880
                                                        maximalConnectionsCount:5
                                                                      chunkSize:40
                                                              connectionTimeout:4
                                                     eventLoopMicrosecondsDelay:40
                                                  errorsBeforeConnectionClosing:3];

// Port - A number in range from 0 to 65535
// Chunk size - Buffer size
// Connection Timeout - Time of inactivity after which client's connection is going to be closed
// Maximal connections count - Number of clients allowed to connect
// Eventloop microseconds delay - Interval between server's main loop evaluations. Adjust depending on your network speed and device's resources utilization
// Errors begore connection closing - Number of errors after which the connection will be closed
```
Create a server with this specific configuration. By default all notification will be passed to the main dispatch queue.
```objective-c
NSObject<ServerHandle> * asyncServer = [[Server alloc] initWithConfiguratoin:configuration];
```
If you wish to use a different queue then create an instance in the following way:
```objective-c
server = [[Server alloc] initWithConfiguratoin:configuration 
                             notificationQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
```
Notifications will be send only if the delegate of the server is set. Otherwise connections won't be accepted and data received. To receive notifications implement `ServerDelegate` protocol.
<h4>ServerDelegate</h4>

**Interface**
```objective-c
@interface ServerHandler: NSObject<ServerDelegate>
@end
```
**Implementation**
```objective-c
@implementation ServerHandler
-(void)newClientHasConnected: (Connection*) connection {
    // Handle the connection here somehow, set connection's delegate
}
-(void)clientHasDisconnected: (Connection*) connection {
    // Ivoked when a client disconnected or the connection hung 
}
@end
```
<h4>ClientDelegate</h4>

If you want to use client analyse interface below:
```objective-c
@interface ClientHandler: NSObject<ClientDelegate>
@end
```
**Implementation**
```objective-c
@implementation ClientHandler
-(void)connectionHasBeenEstablished: (Connection *) connection {
    // Handle the connection here somehow, set connection's delegate
}
-(void)connectionHasBeenClosed: (Connection*) connection {
    // Ivoked when a client disconnected or the connection hung 
}
@end
```
One additional step to make is to implement `ConnectionDelegate` protocol. It is an interface which lets you receive a notification when data is received. Set an instance as `ConnectionDelegate` as soon as you receive `newClientHasConnected` callback in case of `ServerDelegate` or `connectionHasBeenEstablished` in case of `ClientDelegate`.
<h4>ConnectionDelegate</h4>

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
@end
```
