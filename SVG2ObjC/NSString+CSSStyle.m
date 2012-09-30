//
//  NSString+CSSStyle.m
//  SVG2ObjC
//
//  Created by Daniel Parnell on 30/09/12.
//  Copyright (c) 2012 Automagic Software Pty Ltd. All rights reserved.
//

#import "NSString+CSSStyle.h"
#import <Cocoa/Cocoa.h>

@implementation NSString (CSSStyle)

- (NSDictionary*) cssStyles {
    NSMutableDictionary* result = [NSMutableDictionary new];
    NSScanner* scanner = [NSScanner scannerWithString: self];
    NSCharacterSet* colon = [NSCharacterSet characterSetWithCharactersInString: @":"];
    NSCharacterSet* semiColon = [NSCharacterSet characterSetWithCharactersInString: @";"];
    NSString* name;
    NSString* value;
    
    while([scanner scanUpToCharactersFromSet: colon intoString: &name]) {
        // eat the :
        [scanner scanCharactersFromSet: colon intoString: nil];
        
        if([scanner scanUpToCharactersFromSet: semiColon intoString: &value]) {
            // eat the ;
            [scanner scanCharactersFromSet: semiColon intoString: nil];
            
            name = [[name stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
            value = [value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            [result setObject: value forKey: name];
        }
    }
    return result;
}

- (BOOL) cssColourToRed:(CGFloat*)red green:(CGFloat*)green andBlue:(CGFloat*)blue {
    if([self hasPrefix: @"#"]) {
        // it is a hex colour value
        NSScanner* scanner = [NSScanner scannerWithString: self];
        unsigned int colourValue;
        // skip over the #
        [scanner setScanLocation: 1];
        
        if([scanner scanHexInt: &colourValue]) {
            if([self length] == 4) {
                // it is a short colour value
                *red = ((colourValue >> 8) & 0xf) / 15.0f;
                *green = ((colourValue >> 4) & 0xf) / 15.0f;
                *blue = (colourValue & 0xf) / 15.0f;
            } else {
                // it is a long colour value
                *red = ((colourValue >> 16) & 0xff) / 255.0f;
                *green = ((colourValue >> 8) & 0xff) / 255.0f;
                *blue = (colourValue & 0xff) / 255.0f;                
            }
            
            return YES;
        }
    } else {
        id klass = [NSColor class];
        SEL msg = NSSelectorFromString([NSString stringWithFormat: @"%@Color", [self lowercaseString]]);
        
        if([klass respondsToSelector: msg]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSColor* color = [klass performSelector: msg];
#pragma clang diagnostic pop
            
            [color getRed: red green: green blue: blue alpha: nil];
            
            return YES;
        }
    }
    
    return NO;
}

@end
