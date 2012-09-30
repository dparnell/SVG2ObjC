//
//  NSString+SVGPath.m
//  SVG2ObjC
//
//  Created by Daniel Parnell on 23/09/12.
//  Copyright (c) 2012 Automagic Software Pty Ltd. All rights reserved.
//

#import "NSString+SVGPath.h"

@implementation NSString (SVGPath)

- (NSArray*) svgPathTokens {
    NSMutableArray* result = [NSMutableArray new];
    NSScanner* scanner = [NSScanner scannerWithString: self];
    NSCharacterSet* separators = [NSCharacterSet characterSetWithCharactersInString: @" \t\r\n,"];
    NSCharacterSet* commands = [NSCharacterSet characterSetWithCharactersInString: @"MmZzLlHhVvCcSsQqTtAa"];
    NSString* command;
    
    while([scanner scanCharactersFromSet: commands intoString: &command]) {
        [result addObject: command];

        // eat any separators
        [scanner scanCharactersFromSet: separators intoString: nil];
        
        float f;
        while([scanner scanFloat: &f]) {
            [result addObject: [NSNumber numberWithFloat: f]];
            
            // eat any separators
            [scanner scanCharactersFromSet: separators intoString: nil];
        }
    }
    return result;
}

@end
