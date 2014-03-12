//
//  CYContext.h
//  CYContext
//
//  Created by Conrad Kramer on 8/25/13.
//  Copyright (c) 2013 Kramer Software Productions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

extern NSString * const CYErrorLineKey;
extern NSString * const CYErrorNameKey;
extern NSString * const CYErrorMessageKey;

@interface CYContext : NSObject {
    JSGlobalContextRef _context;
}

+ (BOOL)isAvailable;

- (NSString *)evaluateCycript:(NSString *)cycript error:(NSError **)error;

@end
