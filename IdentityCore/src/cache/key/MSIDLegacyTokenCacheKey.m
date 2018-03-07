// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MSIDLegacyTokenCacheKey.h"

//A special attribute to write, instead of nil/empty one.
static NSString *const s_nilKey = @"CC3513A0-0E69-4B4D-97FC-DFB6C91EE132";
static NSString *const s_adalLibraryString = @"MSOpenTech.ADAL.1";
static NSString *const s_adalServiceFormat = @"%@|%@|%@|%@";

@interface MSIDLegacyTokenCacheKey()

@end

@implementation MSIDLegacyTokenCacheKey

#pragma mark - Helpers

//We should not put nil keys in the keychain. The method substitutes nil with a special GUID:
+ (NSString *)getAttributeName:(NSString *)original
{
    return ([NSString msidIsStringNilOrBlank:original]) ? s_nilKey : [original msidBase64UrlEncode];
}

+ (NSString *)serviceWithAuthority:(NSURL *)authority
                          resource:(NSString *)resource
                          clientId:(NSString *)clientId
{
    
    return [NSString stringWithFormat:s_adalServiceFormat,
            s_adalLibraryString,
            authority.absoluteString.msidBase64UrlEncode,
            [self.class getAttributeName:resource],
            clientId.msidBase64UrlEncode];
}

#pragma mark - Legacy keys

+ (MSIDLegacyTokenCacheKey *)keyForLegacySingleResourceTokenWithAuthority:(NSURL *)authority
                                                                 clientId:(NSString *)clientId
                                                                 resource:(NSString *)resource
{
    NSString *service = [self.class serviceWithAuthority:authority
                                                resource:resource
                                                clientId:clientId];
    
    MSIDLegacyTokenCacheKey *key = [[MSIDLegacyTokenCacheKey alloc] initWithAccount:[self adalAccountWithUserId:@""]
                                                                            service:service
                                                                            generic:[s_adalLibraryString dataUsingEncoding:NSUTF8StringEncoding]
                                                                               type:nil];
    
    return key;
}


+ (MSIDLegacyTokenCacheKey *)keyWithAuthority:(NSURL *)authority
                                     clientId:(NSString *)clientId
                                     resource:(NSString *)resource
                                 legacyUserId:(NSString *)legacyUserId
{
    // For legacy token cache both key and query should produce the same result
    // The separation here is just for clarity and possible future optimisations
    return [self queryWithAuthority:authority
                           clientId:clientId
                           resource:resource
                       legacyUserId:legacyUserId];
}

+ (MSIDLegacyTokenCacheKey *)queryWithAuthority:(NSURL *)authority
                                       clientId:(NSString *)clientId
                                       resource:(NSString *)resource
                                   legacyUserId:(NSString *)legacyUserId
{
    NSString *service = [self.class serviceWithAuthority:authority
                                                resource:resource
                                                clientId:clientId];
    
    MSIDLegacyTokenCacheKey *key = [[MSIDLegacyTokenCacheKey alloc] initWithAccount:[self adalAccountWithUserId:legacyUserId]
                                                                            service:service
                                                                            generic:[s_adalLibraryString dataUsingEncoding:NSUTF8StringEncoding]
                                                                               type:nil];
    
    return key;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _account = [coder decodeObjectOfClass:[NSString class] forKey:@"account"];
    _service = [coder decodeObjectOfClass:[NSString class] forKey:@"service"];
    _type = [coder decodeObjectOfClass:[NSNumber class] forKey:@"type"];
    
    // Backward compatibility with ADAL.
    if (!_service)
    {
        NSString *authority = [coder decodeObjectOfClass:[NSString class] forKey:@"authority"];
        NSString *resource = [coder decodeObjectOfClass:[NSString class] forKey:@"resource"];
        NSString *clientId = [coder decodeObjectOfClass:[NSString class] forKey:@"clientId"];
        
        _service = [self.class serviceWithAuthority:[authority msidUrl] resource:resource clientId:clientId];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_account forKey:@"account"];
    [coder encodeObject:_service forKey:@"service"];
    [coder encodeObject:_type forKey:@"type"];

    // Backward compatibility with ADAL.
    if (_service)
    {
        NSArray<NSString *> * items = [_service componentsSeparatedByString:@"|"];
        if (items.count == 4) // See s_adalServiceFormat.
        {
            NSString *authority = [items[1] msidBase64UrlDecode];
            [coder encodeObject:authority forKey:@"authority"];
            
            NSString *resource = [items[2] isEqualToString:s_nilKey] ? nil : [items[2] msidBase64UrlDecode];
            [coder encodeObject:resource forKey:@"resource"];
            
            NSString *clientId = [items[3] msidBase64UrlDecode];
            [coder encodeObject:clientId forKey:@"clientId"];
        }
    }
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object
{
    if (self == object)
    {
        return YES;
    }
    
    if (![object isKindOfClass:MSIDTokenCacheKey.class])
    {
        return NO;
    }
    
    return [self isEqualToTokenCacheKey:(MSIDLegacyTokenCacheKey *)object];
}

- (BOOL)isEqualToTokenCacheKey:(MSIDLegacyTokenCacheKey *)key
{
    if (!key)
    {
        return NO;
    }
    
    BOOL result = YES;
    result &= (!self.account && !key.account) || [self.account isEqualToString:key.account];
    result &= (!self.service && !key.service) || [self.service isEqualToString:key.service];
    result &= (!self.type && !key.type) || [self.type isEqualToNumber:key.type];
    
    return result;
}

- (NSUInteger)hash
{
    NSUInteger hash = 17;
    hash = hash * 31 + self.account.hash;
    hash = hash * 31 + self.service.hash;
    hash = hash * 31 + self.type.hash;
    
    return hash;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    MSIDLegacyTokenCacheKey *key = [[MSIDLegacyTokenCacheKey allocWithZone:zone] init];
    key.account = [self.account copyWithZone:zone];
    key.service = [self.service copyWithZone:zone];
    key.type = [self.type copyWithZone:zone];
    
    return key;
}

#pragma mark - Private
/*
 In order to be backward compatable with legacy format
 in ADAL we must to encode userId as base64 string
 for iOS only. For ADAL Mac we don't encode upn.
 */
+ (NSString *)adalAccountWithUserId:(NSString *)userId
{
#if TARGET_OS_IPHONE
    return [userId msidBase64UrlEncode];
#endif
    
    return userId;
}

@end