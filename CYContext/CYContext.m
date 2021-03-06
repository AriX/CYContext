//
//  CYContext.m
//  CYContext
//
//  Created by Conrad Kramer on 8/25/13.
//  Copyright (c) 2013 Kramer Software Productions, LLC. All rights reserved.
//

#import "CYContext.h"
#import <cycript/cycript.h>

NSString * const CYErrorLineKey = @"CYErrorLineKey";
NSString * const CYErrorNameKey = @"CYErrorNameKey";
NSString * const CYErrorMessageKey = @"CYErrorMessageKey";

@implementation CYContext

+ (BOOL)isAvailable {
    return (CydgetSetupContext != NULL && CydgetMemoryParse != NULL && JSGlobalContextCreate != NULL);
}

- (instancetype)init {
    if (![[self class] isAvailable]) {
        [self release];
        return nil;
    }

    self = [super init];
    if (!self)
        return nil;

    _context = JSGlobalContextCreate(NULL);
    CydgetSetupContext(_context);

    return self;
}

- (void)dealloc {
    JSGlobalContextRelease(_context);

    [super dealloc];
}

- (NSString *)evaluateCycript:(NSString *)cycript error:(NSError **)error {
    // Parse Cycript into Javascript
    size_t length = cycript.length;
    unichar *buffer = malloc(length * sizeof(unichar));
    [cycript getCharacters:buffer range:NSMakeRange(0, length)];
    const uint16_t *characters = buffer;
    CydgetMemoryParse(&characters, &length);
    JSStringRef expression = JSStringCreateWithCharacters(characters, length);

    // Evaluate the Javascript
    JSValueRef exception = NULL;
    JSValueRef result = JSEvaluateScript(_context, expression, NULL, NULL, 0, &exception);
    free(buffer);
    JSStringRelease(expression);

    NSString *resultString = nil;

    // If a result was returned, convert it into an NSString
    if (result) {
        JSStringRef string = JSValueToStringCopy(_context, result, &exception);
        if (string) {
            resultString = [(NSString *)JSStringCopyCFString(kCFAllocatorDefault, string) autorelease];
            JSStringRelease(string);
        }
    }

    // If an exception was thrown, convert it into an NSError
    if (exception && error) {
        JSObjectRef exceptionObject = JSValueToObject(_context, exception, NULL);

        NSInteger line = (NSInteger)JSValueToNumber(_context, JSObjectGetProperty(_context, exceptionObject, JSStringCreateWithUTF8CString("line"), NULL), NULL);

        JSStringRef string = JSValueToStringCopy(_context, JSObjectGetProperty(_context, exceptionObject, JSStringCreateWithUTF8CString("name"), NULL), NULL);
        NSString *name = (NSString *)JSStringCopyCFString(kCFAllocatorDefault, string);
        JSStringRelease(string);

        string = JSValueToStringCopy(_context, JSObjectGetProperty(_context, exceptionObject, JSStringCreateWithUTF8CString("message"), NULL), NULL);
        NSString *message = (NSString *)JSStringCopyCFString(kCFAllocatorDefault, string);
        JSStringRelease(string);

        string = JSValueToStringCopy(_context, exception, NULL);
        NSString *description = (NSString *)JSStringCopyCFString(kCFAllocatorDefault, string);
        JSStringRelease(string);

        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:@(line) forKey:CYErrorLineKey];
        [userInfo setValue:name forKey:CYErrorNameKey];
        [userInfo setValue:message forKey:CYErrorMessageKey];
        [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"CYContextDomain" code:0 userInfo:userInfo];
        
        [name release];
        [message release];
        [description release];
    }

    return resultString;
}

@end
