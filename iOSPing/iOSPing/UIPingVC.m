//
//  UIPingVC.m
//  iOSWorkshop
//
//  Created by Pedro Ontiveros on 9/6/15.
//  Copyright © 2015 Pedro Ontiveros. All rights reserved.
//

#import "UIPingVC.h"
#include <sys/socket.h>
#include <netdb.h>


static NSString * DisplayAddressForAddress(NSData * address)
// Returns a dotted decimal string for the specified address (a (struct sockaddr)
// within the address NSData).
{
    int         err;
    NSString *  result;
    char        hostStr[NI_MAXHOST];
    
    result = nil;
    
    if (address != nil) {
        err = getnameinfo([address bytes], (socklen_t) [address length], hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
        if (err == 0) {
            result = [NSString stringWithCString:hostStr encoding:NSASCIIStringEncoding];
            assert(result != nil);
        }
    }
    
    return result;
}

@implementation UIPingVC

@synthesize pinger;

- (void)viewDidLoad
{
    self.title = @"Ping";
}

- (IBAction)onTouchPing:(id)sender
{
    UIButton *button = (UIButton*)sender;
    if (button.tag == 1) {
        button.tag = 0;
        [button setTitle:@"Ping" forState:UIControlStateNormal];
        [self.sendTimer invalidate];
        [self.remote setEnabled:YES];
        self.sendTimer = nil;
    } else {
        button.tag = 1;
        [button setTitle:@"Stop" forState:UIControlStateNormal];
        [self.remote setEnabled:NO];
        
        if (self.remote.text.length > 0) {
            assert(self.pinger == nil);
            [self.console setText:@""];
            self.pinger = [SimplePing simplePingWithHostName:self.remote.text];
            self.pinger.delegate = self;
            [self.pinger start];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"Please check remote address."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"Accept"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {
                                                               NSLog(@"What I have to do here ?");
                                                           }];
            [alert addAction:action];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (IBAction)onTouchClear:(id)sender
{
    [self.console setText:@""];
}

- (void)sendPing
{
    // Called to send a ping, both directly (as soon as the SimplePing object starts up)
    // and via a timer (to continue sending pings periodically).
    assert(self.pinger != nil);
    [self.pinger sendPingWithData:nil];
}

#pragma mark - SimplePingDelegate
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
{
    // Called after the SimplePing has successfully started up.  After this callback, you
    // can start sending pings via -sendPingWithData:
    #pragma unused(pinger)
    assert(pinger == self.pinger);
    assert(address != nil);
    
    NSString *logIP = [NSString stringWithFormat:@"pinging to %@\n", DisplayAddressForAddress(address)];
    NSLog(@"%@", logIP);
    [self.console setText:logIP];
//    NSLog(@"pinging %@", DisplayAddressForAddress(address));
    // Send the first ping straight away.
    [self sendPing];
    
    // And start a timer to send the subsequent pings.
    
    assert(self.sendTimer == nil);
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(sendPing) userInfo:nil repeats:YES];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
{
    // If this is called, the SimplePing object has failed.  By the time this callback is
    // called, the object has stopped (that is, you don't need to call -stop yourself).
    #pragma unused(pinger)
    assert(pinger == self.pinger);
    
    #pragma unused(error)
    NSLog(@"failed: %@", [error description]);
    // No need to call -stop.  The pinger will stop itself in this case.
    // We do however want to nil out pinger so that the runloop stops.
    
    [self.console setText:[error description]];
    self.pinger = nil;
}

// IMPORTANT: On the send side the packet does not include an IP header.
// On the receive side, it does.  In that case, use +[SimplePing icmpInPacket:]
// to find the ICMP header within the packet.

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet
{
    // Called whenever the SimplePing object has successfully sent a ping packet.
    #pragma unused(pinger)
    assert(pinger == self.pinger);
    #pragma unused(packet)
    NSMutableString *log = [NSMutableString stringWithFormat:@"%@", self.console.text];
//    ////////    ////////    ////////    ////////    ////////
//    unsigned int limit = (unsigned int)[packet length];
//    char *content = (char*)[packet bytes];
//    for (int i = 0; i < limit; i++) {
//        printf("%c", content[i]);
//    }
//    ////////    ////////    ////////    ////////    ////////
    NSString *tmpLog = [NSString stringWithFormat:@"#%u sent", (unsigned int) OSSwapBigToHostInt16(((const ICMPHeader *) [packet bytes])->sequenceNumber) ];
    NSLog(@"%@",tmpLog);
    [log appendFormat:@"%@\n", tmpLog];
    [self.console setText:log];
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error
{
    // Called whenever the SimplePing object tries and fails to send a ping packet.
    NSLog(@"didFailToSendPacket");
    
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
{
    // Called whenever the SimplePing object receives an ICMP packet that looks like
    // a response to one of our pings (that is, has a valid ICMP checksum, has
    // an identifier that matches our identifier, and has a sequence number in
    // the range of sequence numbers that we've sent out).
    #pragma unused(pinger)
    assert(pinger == self.pinger);
    #pragma unused(packet)
    ////////    ////////    ////////    ////////    ////////
    unsigned int limit = (unsigned int)[packet length];
    char *content = (char*)[packet bytes];
    for (int i = 0; i < limit; i++) {
        printf("%c", content[i]);
    }
    ////////    ////////    ////////    ////////    ////////
    NSMutableString *log = [NSMutableString stringWithFormat:@"%@", self.console.text];
    NSString *tmpLog = [NSString stringWithFormat:@"#%u received", (unsigned int) OSSwapBigToHostInt16([SimplePing icmpInPacket:packet]->sequenceNumber)];
    NSLog(@"%@", tmpLog);
    [log appendFormat:@"%@\n", tmpLog];
    [self.console setText:log];
}

- (void)simplePing:(SimplePing *)pinger didReceiveUnexpectedPacket:(NSData *)packet
{
    // Called whenever the SimplePing object receives an ICMP packet that does not
    // look like a response to one of our pings.
    NSLog(@"Receiving unexpected package from remote address.");
}

@end