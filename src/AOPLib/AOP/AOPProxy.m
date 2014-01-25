
//  AOPProxy.m  InnoliFoundation
//  Created by Szilveszter Molnar on 1/7/11.  Copyright 2011 Innoli Kft. All rights reserved.

#import "AOPProxy.h"
#import "AOPInterceptorInfo.h"

@implementation AOPProxy { id parentObject;  NSMutableArray *methodStartInterceptors, *methodEndInterceptors; }

- (id) initWithInstance:(id)anObject {

  parentObject            = anObject;
  methodStartInterceptors = NSMutableArray.new;
  methodEndInterceptors   = NSMutableArray.new;    return self;
}

- (id) initWithNewInstanceOfClass:(Class) class {

  // create a new instance of the specified class
  return self = [self initWithInstance:[class new]] ? self : nil;     // invoke my designated initializer
}
- (BOOL) isKindOfClass:     (Class)cls;       { return [parentObject isKindOfClass:cls];        }
- (BOOL) conformsToProtocol:(Protocol*)proto  { return [parentObject conformsToProtocol:proto]; }
- (BOOL) respondsToSelector:(SEL)sel          { return [parentObject respondsToSelector:sel];   }

- (NSMethodSignature*) methodSignatureForSelector:(SEL)sel { return [parentObject methodSignatureForSelector:sel];
}

- (void)interceptMethodStartForSelector:(SEL)sel withInterceptorTarget:(id)target interceptorSelector:(SEL)selector {

  NSParameterAssert(target != nil);                   // make sure the target is not nil

  AOPInterceptorInfo *info = AOPInterceptorInfo.new;  // create the interceptorInfo
  info.interceptedSelector = sel;
  info.interceptorTarget   = target;
  info.interceptorSelector = selector;
  [methodStartInterceptors addObject:info];           // add to our list
}

- (void)interceptMethodEndForSelector:(SEL)sel withInterceptorTarget:(id)target interceptorSelector:(SEL)selector {

  NSParameterAssert(target != nil);                   // make sure the target is not nil

  AOPInterceptorInfo *info  = AOPInterceptorInfo.new; // create the interceptorInfo
  info.interceptedSelector  = sel;
  info.interceptorTarget    = target;
  info.interceptorSelector  = selector;
  [methodEndInterceptors addObject:info];             // add to our list
}

- (void)invokeOriginalMethod:(NSInvocation *)inv { [inv invoke]; }

- (void)forwardInvocation:(NSInvocation *)inv {

  SEL aSelector = inv.selector;
  if (![parentObject respondsToSelector:aSelector]) return;   // check if the parent object responds to the selector ...
  inv.target = parentObject;

  void (^invokeSelectors)(NSArray*) = ^(NSArray*interceptors){ @autoreleasepool {
    // Intercept the start/end of the method, depending on passed array.
    [interceptors enumerateObjectsUsingBlock:^(AOPInterceptorInfo *oneInfo, NSUInteger idx, BOOL *stop) {
      if (oneInfo.interceptedSelector != aSelector) return;                 // first search for this selector ...

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

      [(NSObject*)oneInfo.interceptorTarget performSelector:oneInfo.interceptorSelector withObject:inv];

#pragma clang diagnostic pop
      }];
    }
  };

  // Intercept the starting of the method.
  invokeSelectors(methodStartInterceptors);
  // Invoke the original method ...
  [self invokeOriginalMethod:inv];
   // Intercept the ending of the method.
  invokeSelectors(methodEndInterceptors);
  //	else { [super forwardInvocation:invocation]; }
}

@end
